module Utils
  # Utility methods for manipulating text
  module Text
    # Try to make names more friendly
    def friendly_name(long_name)
      long_name.split(/\s/).first
    end

    # Strip off bad characters 
    def sanitze_for_chat(text)
      # Remove bash colorings
      text.gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]/, '')
    end
  end
end
