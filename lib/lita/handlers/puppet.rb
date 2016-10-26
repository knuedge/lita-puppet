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

        Timeout::timeout(600) do
          puppet_master = Rye::Box.new(config.master_hostname, user: user)
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
          puppet_master.disconnect
        end

        # build a reply
        response.reply("#{username}, your r10k deployment is done!")
        if ret
          response.reply "/code " + ret.stderr.join("\n")
        else
          response.reply "But didn't seem to work... I think it may have timed out."
        end
      end

      def puppet_agent_run(response)
        host = response.matches[0][4]
        user = config.ssh_user || 'lita'
        username = response.user.name

        response.reply("#{username}, I'll run puppet right away. Give me a sec and I'll let you know how it goes.")

        ret = nil

        Timeout::timeout(300) do
          remote = Rye::Box.new(host, user: user)
          remote.cd '/tmp'

          # Need to use sudo from here on
          remote.enable_sudo

          # scary...
          remote.disable_safe_mode

          ret = remote.execute 'puppet agent -t'
          remote.disconnect
        end

        # build a reply
        if ret
          response.reply "#{username}, that puppet run is complete! It exited with status #{ret.exit_status}."
        else
          response.reply "#{username}, your puppet run is done, but didn't seem to work... I think it may have timed out."
        end
      end

      Lita.register_handler(self)
    end
  end
end
