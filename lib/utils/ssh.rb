module Utils
  # Utility methods for doing things over SSH
  module SSH
    # Intelligently do some things over SSH
    def over_ssh(opts = {})
      result = {}
      fail "MissingSSHHost" unless opts[:host]
      fail "MissingSSHUser" unless opts[:user]
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
        Timeout::timeout(opts[:timeout]) do
          yield remote # pass our host back to the user to work with
        end
      rescue Rye::Err => e
        exception = e
      rescue StandardError => e
        exception = e
      rescue Exception => e
        exception = e
      ensure
        remote.disconnect
      end

      if exception
        result[:exception] = exception
      else
        result[:exit_status] = output.exit_status
        result[:stdout] = output.stdout
        result[:stderr] = output.stderr
      end
      return result
    end
  end
end
