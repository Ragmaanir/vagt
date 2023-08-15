module Vagt
  class Error
    alias Attr = String | Int32 | Bool

    getter name : String
    getter attributes : Hash(String, Attr)

    # getter value

    def initialize(value : _, @name, @attributes = {} of String => Attr)
    end
  end

  abstract class Node
    getter errors : Array(Error)

    def initialize(@errors)
    end
  end

  class PropertyNode < Node
  end

  class ObjectNode < PropertyNode
    getter nested_errors : Hash(String, Node)

    delegate :[], :[]?, :has_key?, to: nested_errors

    def initialize(@errors, @nested_errors)
    end
  end

  class ArrayNode < PropertyNode
    getter nested_errors : Hash(Int32, Node)

    delegate :[], :[]?, :has_key?, to: nested_errors

    def initialize(@errors, @nested_errors)
    end
  end
end
