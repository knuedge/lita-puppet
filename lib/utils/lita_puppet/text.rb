module Utils
  module LitaPuppet
    # Utility methods for manipulating text
    module Text
      # Strip off bad characters
      def sanitze_for_chat(text)
        # Remove bash colorings
        text.gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]/, '')
      end

      # camel case puppet classes
      def class_camel(text)
        text.split('::').map(&:capitalize).join('::')
      end

      # Format some text as code
      #  Note that this is HipChat specific for the moment
      # TODO: Make this *not* HipChat specific
      def as_code(text)
        '/code ' + sanitze_for_chat(text)
      end

      def r10k_command(environment, mod)
        command = 'r10k deploy'
        if environment && mod
          command << " module -e #{environment} #{mod} -v"
        else
          command << ' environment'
          command << " #{environment}" if environment
          command << ' -pv'
        end
      end

      def agent_command
        command = 'puppet agent'
        command << ' --onetime --verbose --no-daemonize'
        command << ' --no-usecacheonfailure'
        command << ' --no-splay --show_diff 2>&1'
      end
    end
  end
end
