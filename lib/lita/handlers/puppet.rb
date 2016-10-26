module Lita
  module Handlers
    class Puppet < Handler
      namespace 'Puppet'
      config :master_hostname, required: true, type: String
      config :ssh_user, required: false, type: String
      config :control_repo_path, required: false, type: String

      route(
        /(puppet|pp)\s+(r10k|deploy)(\s(\S+))?/i,
        :r10k_deploy,
        command: true,
        help: {
          "puppet r10k [env]" => "Deploy the latest puppet code on the puppet master via r10k, optionally specifying an environment."
        }
      )

      route(
        /(puppet|pp)(\s+agent)?\s+(run)(\s+on)?\s(\S+)/i,
        :puppet_agent_run,
        command: true,
        help: {
          "puppet agent run on <host>" => "Run the puppet agent on <host>."
        }
      )

      def r10k_deploy(response)
        environment = response.matches[0][3]
        control_repo = config.control_repo_path || '/opt/puppet/control'
        user = config.ssh_user || 'lita'
        username = response.user.name

        response.reply("#{username}, I'll get right on that. Give me a moment and I'll let you know how it went.")

        ret = nil

        # TODO: better error handling
        puppet_master = Rye::Box.new(
          config.master_hostname,
          user: user,
          password_prompt: false
        )

        begin
          Timeout::timeout(600) do
            puppet_master.cd control_repo

            # Need to use sudo from here on
            puppet_master.enable_sudo

            puppet_master.git :pull

            # scary...
            puppet_master.disable_safe_mode
            command = "r10k deploy environment"
            command << " #{environment}" if environment
            command << ' -pv'
            ret = puppet_master.execute command
          end
        rescue Exception => e
          exception = e
        ensure
          puppet_master.disconnect
        end

        # build a reply
        if ret
          response.reply("#{username}, your r10k deployment is done!")
          response.reply "/code " + ret.stderr.join("\n")
        else
          response.reply "#{username}, your r10k run didn't seem to work... I think it may have timed out."
          response.reply "/code " + exception.message
        end
      end

      def puppet_agent_run(response)
        host = response.matches[0][4]
        user = config.ssh_user || 'lita'
        username = response.user.name

        response.reply("#{username}, I'll run puppet right away. Give me a sec and I'll let you know how it goes.")

        ret = nil
        exception = nil

        # TODO: better error handling
        remote = Rye::Box.new(
          host,
          user: user,
          password_prompt: false
        )

        begin
          Timeout::timeout(300) do
            remote.cd '/tmp'

            # Need to use sudo from here on
            remote.enable_sudo

            # scary...
            remote.disable_safe_mode

            # build up the command
            command = 'puppet agent'
            command << ' --verbose --no-daemonize'
            command << ' --no-usecacheonfailure'
            command << ' --no-splay --show_diff'

            ret = remote.execute command
          end
        rescue Exception => e
          exception = e
        ensure
          remote.disconnect
        end

        # build a reply
        if ret
          response.reply "#{username}, that puppet run is complete! It exited with status #{ret.exit_status}."
          # Send the standard out, but strip off the bash color code stuff...
          response.reply "/code " + ret.stdout.join("\n").gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]/, '')
        else
          response.reply "#{username}, your puppet run is done, but didn't seem to work... I think it may have timed out."
          response.reply "/code " + exception.message
        end
      end

      Lita.register_handler(self)
    end
  end
end
