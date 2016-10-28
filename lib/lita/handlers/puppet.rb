module Lita
  module Handlers
    class Puppet < Handler
      namespace 'Puppet'
      config :master_hostname, required: true, type: String
      config :ssh_user, required: false, type: String
      config :control_repo_path, required: false, type: String
      config :puppetdb_url, required: false, type: String

      route(
        /(puppet|pp)(\s+agent)?\s+(run)(\s+on)?\s+(\S+)/i,
        :puppet_agent_run,
        command: true,
        help: {
          "puppet agent run on <host>" => "Run the puppet agent on <host>."
        }
      )

      route(
        /(puppet|pp)\s+(cert)\s+(clean)\s+(\S+)/i,
        :cert_clean,
        command: true,
        help: {
          "puppet cert clean <host>" => "Remove all traces of the SSL cert for <host> on the Puppet Master."
        }
      )

      route(
        /(puppet|pp)\s+(catalog|node)\s+(\S+)\s+(profiles)/i,
        :node_profiles,
        command: true,
        help: {
          "puppet catalog <host> profiles" => "Query PuppetDB to get a list of all roles and profiles applied to <host>."
        }
      )

      route(
        /(puppet|pp)\s+(class)\s+(nodes)\s+(\S+)/i,
        :class_nodes,
        command: true,
        help: {
          "puppet class nodes <class>" => "Query PuppetDB to get a list of all nodes containing a class."
        }
      )

      route(
        /(puppet|pp)\s+(r10k|deploy)(\s+(\S+)(\s+(\S+))?)?/i,
        :r10k_deploy,
        command: true,
        help: {
          "puppet r10k [env [module]]" => "Deploy the latest puppet code on the puppet master via r10k, optionally specifying an environment, and possibly a module."
        }
      )

      include ::Utils::PuppetDB
      include ::Utils::SSH
      include ::Utils::Text

      def cert_clean(response)
        cert = response.matches[0][3]
        user = config.ssh_user || 'lita'
        username = friendly_name(response.user.name)

        response.reply("#{username}, working on that `puppet cert clean`. I'll get right back to you.")

        result = over_ssh(host: config.master_hostname, user: user, timeout: 120) do |server|
          server.cd '/tmp'
          # Need to use sudo
          server.enable_sudo
          # scary...
          server.disable_safe_mode

          server.execute "puppet cert clean #{cert} 2>&1"
        end

        if result[:exception]
          response.reply "#{username}, your `puppet cert clean` didn't seem to work... ;-("
          response.reply "/code " + result[:exception].message
          return false
        end

        # build a reply
        response.reply("#{username}, your `puppet cert clean` is all done!")
        reply_content = [result[:stdout].join("\n"), result[:stderr].join("\n")].join("\n")
        response.reply "/code " + sanitze_for_chat(reply_content)
      end

      def puppet_agent_run(response)
        host = response.matches[0][4]
        user = config.ssh_user || 'lita'
        username = friendly_name(response.user.name)

        response.reply("#{username}, I'll run puppet right away. Give me a sec and I'll let you know how it goes.")

        result = over_ssh(host: host, user: user) do |server|
          server.cd '/tmp'

          # Need to use sudo from here on
          server.enable_sudo

          # scary...
          server.disable_safe_mode

          # build up the command
          command = 'puppet agent'
          command << ' --onetime --verbose --no-daemonize'
          command << ' --no-usecacheonfailure'
          command << ' --no-splay --show_diff 2>&1'

          server.execute command
        end

        # build a reply
        if !result[:exception]
          response.reply "#{username}, that puppet run is complete! It exited with status #{result[:exit_status]}."
          # Send the standard out, but strip off the bash color code stuff...
          response.reply "/code " + sanitze_for_chat(result[:stdout].join("\n"))
        else
          response.reply "#{username}, your puppet run is done, but didn't seem to work... I think it may have timed out."
          response.reply "/code " + result[:exception].message
        end
      end

      def node_profiles(response)
        host = response.matches[0][2]
        url  = config.puppetdb_url
        username = friendly_name(response.user.name)

        unless url
          cant_reply = "#{username}, I would do that, but I don't know how to connect to PuppetDB."
          cant_reply << "Edit my config and add `config.handlers.puppet.puppetdb_url`."
          response.reply(cant_reply)
          return false
        end

        response.reply("#{username}, let me see what I can find in PuppetDB for you.")

        profiles = node_roles_and_profiles(url, host)
        if profiles.is_a? String
          response.reply("Hmmm, that didn't work. Here's what PuppetDB responded with: '#{profiles}'")
          return false
        else
          response.reply("Here are the profiles and roles for #{host}:")
          response.reply("/code" + profiles.join("\n"))
        end
      end

      def nodes_with_class(response)
        puppet_class = response.matches[3]
        url = config.puppetdb_url
        username = friendly_name(response.user.name)

        unless url
          cant_reply = "#{username}, I would do that, but I don't know how to connect to PuppetDB."
          cant_reply << "Edit my config and add `config.handlers.puppet.puppetdb_url`."
          response.reply(cant_reply)
          return false
        end

        response.reply("#{username}, let me see what I can find in PuppetDB for you.")

        puppet_classes = class_nodes(url, puppet_class)
        if puppet_classes.empty?
          response.reply("There are no nodes with #{puppet_class} class, are you sure its a valid class?")
          return false
        else
          response.reply("Here are all the nodes with class #{puppet_class}:")
          response.reply("/code" + puppet_class.join("\n"))
        end
      end


      def r10k_deploy(response)
        environment = response.matches[0][3]
        mod = response.matches[0][5]
        control_repo = config.control_repo_path || '/opt/puppet/control'
        user = config.ssh_user || 'lita'
        username = friendly_name(response.user.name)

        response.reply("#{username}, I'll get right on that. Give me a moment and I'll let you know how it went.")

        result1 = over_ssh(host: config.master_hostname, user: user, timeout: 120) do |server|
          # Need to use sudo
          server.enable_sudo
          server[control_repo].git :pull
        end

        if result1[:exception]
          response.reply "#{username}, your r10k run didn't seem to work. Looks like there was a problem with Git:"
          response.reply "/code " + result1[:exception].message
          return false
        end

        result2 = over_ssh(host: config.master_hostname, user: user) do |server|
          # Need to use sudo
          server.enable_sudo
          # scary...
          server.disable_safe_mode

          command = "r10k deploy"
          if environment && mod
            command << ' module'
            command << " -e #{environment}"
            command << " #{mod}"
            command << " -v"
          else
            command << " environment"
            command << " #{environment}" if environment
            command << ' -pv'
          end
          server.execute command
        end

        if result2[:exception]
          response.reply "#{username}, your r10k run didn't seem to work... Maybe it timed out?"
          response.reply "/code " + result2[:exception].message
          return false
        end

        # build a reply
        response.reply("#{username}, your r10k deployment is done!")
        reply_content = [result1[:stdout].join("\n"), result2[:stderr].join("\n")].join("\n")
        response.reply "/code " + sanitze_for_chat(reply_content)
      end

      Lita.register_handler(self)
    end
  end
end
