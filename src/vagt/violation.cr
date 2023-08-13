module Vagt
  abstract class Violation
    alias Attr = String | Int32 | Bool

    NONE = [] of Violation

    getter name : String

    def initialize(@name)
    end
  end

  class PropertyViolation(T) < Violation
    getter name : String
    getter attributes : Hash(String, Attr)
    getter value : T

    def initialize(@value, @name, @attributes = {} of String => Attr)
    end
  end

  # class NestedViolations(T) < Violation
  #   getter value : T
  #   getter violations : Hash(String, Array(Violation))

  #   def initialize(@value, @violations)
  #     @name = "nested"
  #   end
  # end

  class NestedViolations(T) < Violation
    getter value : T
    getter result : ValidationResult

    def initialize(@value, @result)
      @name = "nested"
    end
  end
end
