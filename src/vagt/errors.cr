module Vagt
  class Error
    include JSON::Serializable

    alias Attr = String | Int32 | Bool

    getter name : String
    getter attributes : Hash(String, Attr)

    def initialize(@name, @attributes = {} of String => Attr)
    end
  end

  class ObjectError < Error
    getter errors : Hash(String, Array(Error))

    delegate :[], :[]?, :has_key?, to: errors

    def initialize(@errors)
      super("object_invalid")
    end
  end

  class ArrayError < Error
    getter errors : Hash(Int32, ObjectError | Array(Error))

    delegate :[], :[]?, :has_key?, to: errors

    def initialize(@errors)
      super("array_invalid")
    end
  end
end
