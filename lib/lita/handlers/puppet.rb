module Lita
  module Handlers
    class Puppet < Handler
      namespace 'Puppet'
      config :master_hostname, required: true, type: String
      config :ssh_user, required: false, type: String
      config :control_repo_path, required: false, type: String

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
        /(puppet|pp)\s+(r10k|deploy)(\s+(\S+))?/i,
        :r10k_deploy,
        command: true,
        help: {
          "puppet r10k [env]" => "Deploy the latest puppet code on the puppet master via r10k, optionally specifying an environment."
        }
      )

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

          server.execute "puppet cert clean #{cert}"
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
          command << ' --verbose --no-daemonize'
          command << ' --no-usecacheonfailure'
          command << ' --no-splay --show_diff'

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

      def r10k_deploy(response)
        environment = response.matches[0][3]
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

          command = "r10k deploy environment"
          command << " #{environment}" if environment
          command << ' -pv'
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
