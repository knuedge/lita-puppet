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

    # camel case puppet classes
    def class_camel(text)
      text.split('::').map(&:capitalize).join('::')
    end

    # Format some text as code
    #  Note that this is HipChat specific for the moment
    # TODO: Make this *not* HipChat specific
    def as_code(text)
      "/code " + sanitze_for_chat(text)
    end
  end

end
