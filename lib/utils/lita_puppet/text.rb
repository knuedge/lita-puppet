module Utils
  module LitaPuppet
    # Utility methods for manipulating text
    module Text
      def agent_command
        command = 'puppet agent'
        command << ' --onetime --verbose --no-daemonize'
        command << ' --no-usecacheonfailure'
        command << ' --no-splay --show_diff 2>&1'
      end

      # Format some text as code
      #  Note that this is HipChat specific for the moment
      # TODO: Make this *not* HipChat specific
      def as_code(text)
        '/code ' + sanitze_for_chat(text)
      end

      # camel case puppet classes
      def class_camel(text)
        text.split('::').map(&:capitalize).join('::')
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

      # Strip off bad characters
      def sanitze_for_chat(text)
        # Remove bash colorings
        o = text.gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]/, '')
        # Limit text to 50 lines
        o = (o.lines.to_a[0...49] << "\n... truncated to 50 lines").join if o.lines.size > 50
        # return the output
        o
      end
    end
  end
end
