module Lita
  module Handlers
    class Puppet < Handler
      namespace 'Puppet'
      config :master_hostname, required: true, type: String
      config :ssh_user, required: false, type: String, default: 'lita'
      config :puppetdb_url, required: false, type: String
      config :puppetdb_api_vers, required: false, type: String, default: '4'
      config :puppetdb_key, required: true, type: String
      config :puppetdb_cert, required: true, type: String
      config :puppetdb_ca_cert, required: true, type: String

      route(
        /(puppet|pp)(\s+agent)?\s+(run)(\s+on)?\s+(\S+)/i,
        :puppet_agent_run,
        command: true,
        restrict_to: :puppet_admins,
        help: { t('help.puppet_agent_run.syntax') => t('help.puppet_agent_run.desc') }
      )

      route(
        /(puppet|pp)\s+(cert)\s+(clean)\s+(\S+)/i,
        :cert_clean,
        command: true,
        restrict_to: :puppet_admins,
        help: { t('help.cert_clean.syntax') => t('help.cert_clean.desc') }
      )

      route(
        /(puppet|pp)\s+(profiles|roles\sand\sprofiles|roles|r&p)\s+(\S+)/i,
        :node_profiles,
        command: true,
        help: { t('help.node_profiles.syntax') => t('help.node_profiles.desc') }
      )

      route(
        /(puppet|pp)\s+(class)\s+(nodes)\s+(\S+)/i,
        :nodes_with_class,
        command: true,
        help: { t('help.nodes_with_class.syntax') => t('help.nodes_with_class.desc') }
      )

      route(
        /(puppet|pp)\s+(fact)\s+(\S+)\s+(\S+)/i,
        :node_facts,
        command: true,
        help: { t('help.node_facts.syntax') => t('help.node_facts.desc') }
      )

      route(
        /(puppet|pp)\s+(\S+)\s+(info)/i,
        :nodes_info,
        command: true,
        help: { t('help.nodes_info.syntax') => t('help.nodes_info.desc') }
      )

      route(
        /(puppet|pp)\s+(r10k|deploy)(\s+(\S+)(\s+(\S+))?)?/i,
        :r10k_deploy,
        command: true,
        restrict_to: :puppet_admins,
        help: { t('help.r10k_deploy.syntax') => t('help.r10k_deploy.desc') }
      )

      include ::Utils::LitaPuppet::PuppetDB
      include ::Utils::LitaPuppet::SSH
      include ::Utils::LitaPuppet::Text

      def cert_clean(response)
        cert = response.matches[0][3]

        response.reply_with_mention(t('replies.cert_clean.working'))

        result = cert_clean_result(config.master_hostname, config.ssh_user, cert)

        if result[:exception]
          fail_message response, t('replies.cert_clean.failure'), result[:exception].message
        else
          success_message(
            response,
            t('replies.cert_clean.success'),
            (result[:stdout] + result[:stderr]).join("\n")
          )
        end
      end

      def puppet_agent_run(response)
        host = response.matches[0][4]

        response.reply_with_mention(t('replies.puppet_agent_run.working'))

        result = simple_ssh_command(host, config.ssh_user, agent_command)

        # build a reply
        if result[:exception]
          fail_message response, t('replies.puppet_agent_run.failure'), result[:exception].message
        else
          success_message(
            response,
            t('replies.puppet_agent_run.success', status: result[:exit_status]),
            result[:stdout].join("\n")
          )
        end
      end

      def node_profiles(response)
        host = response.matches[0][2]
        what = response.matches[0][1]

        response.reply_with_mention(t('replies.node_profiles.working'))

        profiles = node_roles_and_profiles(what, host)

        if profiles.is_a? String
          fail_message response, t('replies.node_profiles.failure', error: profiles)
        elsif profiles == []
          fail_message response, t('replies.node_profiles.failure_no_roles', host: host)
        else
          success_message(
            response,
            t('replies.node_profiles.success', things: what, host: host),
            profiles.join("\n")
          )
        end
      end

      def nodes_with_class(response)
        puppet_class = response.matches[0][3]

        response.reply_with_mention(t('replies.nodes_with_class.working'))

        puppet_classes = class_nodes(class_camel(puppet_class))
        if puppet_classes.empty?
          fail_message response, t('replies.nodes_with_class.failure', pclass: puppet_class)
        else
          success_message(
            response,
            t('replies.nodes_with_class.success', pclass: puppet_class),
            puppet_classes.join("\n")
          )
        end
      end

      def node_facts(response)
        host = response.matches[0][2]
        fact = response.matches[0][3]
        result = query_fact(host, fact)
        if result.nil?
          response.reply_with_mention(
            t('replies.node_facts.error', host: host)
          )
        else
          response.reply result
        end
      end

      def nodes_info(response)
        host = response.matches[0][1]
        result = node_info(host)
        if result.nil?
          response.reply_with_mention(
            t('replies.nodes_info.error', host: host)
          )
        else
          response.reply result
        end
      end

      # rubocop:disable Metrics/AbcSize
      def r10k_deploy(response)
        environment = response.matches[0][3]
        mod = response.matches[0][5]
        user = config.ssh_user

        response.reply_with_mention(t('replies.r10k_deploy.working'))

        result = simple_ssh_command(config.master_hostname, user, r10k_command(environment, mod))

        if result[:exception]
          fail_message response, t('replies.r10k_deploy.failure'), result[:exception].message
        else
          success_message(
            response,
            t('replies.r10k_deploy.success'),
            [result[:stdout].join("\n"), result[:stderr].join("\n")].join("\n")
          )
        end
      end

      private

      def fail_message(response, message, data = nil)
        response.reply_with_mention(message)
        response.reply(as_code(data)) if data
      end

      alias success_message fail_message

      def cert_clean_result(host, user, cert)
        cmd = "puppet cert clean #{cert} 2>&1"
        simple_ssh_command(host, user, cmd, 120)
      end

      Lita.register_handler(self)
    end
  end
end
