module Vagt
  DEFAULT_VALIDATORS = {
    blacklist: BlacklistValidator,
    size:      SizeValidator,
    range:     RangeValidator,
    format:    FormatValidator,
  }

  module ValueValidator
    NO_ERRORS = [] of Error

    def call(*args)
      {% raise "Invalid argument types for #{@type}.call" %}
    end

    macro included
      def self.call(*args)
        new.call(*args)
      end
    end
  end

  class BlacklistValidator
    include ValueValidator

    def call(blacklist : Proc(_, Bool) | Array, value) : Array(Error)
      invalid = blacklist.is_a?(Proc) ? blacklist.call(value) : blacklist.includes?(value)

      invalid ? [Error.new("blacklist")] : NO_ERRORS
    end
  end

  class SizeValidator
    include ValueValidator

    def call(size : Proc(_, Bool) | Range | Array, value) : Array(Error)
      valid = size.is_a?(Proc) ? size.call(value.size) : size.includes?(value.size)

      valid ? NO_ERRORS : [Error.new("size")]
    end
  end

  class RangeValidator
    include ValueValidator

    def call(range : Range | Proc(_, Bool), value) : Array(Error)
      valid = range.includes?(value)
      valid ? NO_ERRORS : [Error.new("range")]
    end
  end

  class FormatValidator
    include ValueValidator

    def call(fmt : Regex | Proc(_, Bool), value) : Array(Error)
      valid = case fmt
              when Regex then fmt.matches?(value)
              when Proc  then fmt.call(value)
              end

      valid ? NO_ERRORS : [Error.new("format")]
    end
  end
end
