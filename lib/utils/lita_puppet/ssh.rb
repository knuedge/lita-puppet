module Utils
  module LitaPuppet
    # Utility methods for doing things over SSH
    module SSH
      # Intelligently do some things over SSH
      def over_ssh(opts = {})
        raise 'MissingSSHHost' unless opts[:host]
        raise 'MissingSSHUser' unless opts[:user]
        opts[:timeout] ||= 300 # default to a 5 minute timeout

        remote = Rye::Box.new(
          opts[:host],
          user: opts[:user],
          auth_methods: ['publickey'],
          password_prompt: false,
          error: STDOUT # send STDERR to STDOUT for things that actually print
        )

        exception = nil

        # Getting serious about not crashing Lita...
        output = begin
          # pass our host back to the user to work with
          Timeout.timeout(opts[:timeout]) { yield remote }
        rescue Rye::Err, StandardError => e
          exception = e
        ensure
          remote.disconnect
        end

        calculate_result(output, exception)
      end

      def calculate_result(output, exception)
        result = {}
        if exception
          result[:exception] = exception
        else
          result[:exit_status] = output.exit_status
          result[:stdout] = output.stdout
          result[:stderr] = output.stderr
        end
        result
      end
    end
  end
end
