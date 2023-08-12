require "./spec_helper"

describe Vagt do
  class Example
    include JSON::Serializable
    include Vagt::Validated

    schema do
      field name : String
      field age : Int32
      # field x : Int32?
    end
  end

  class ExampleValidator
    include Vagt::Validator(Example)

    BLACKLIST = %w{Admin admin null delete}

    validate :name, format: /\A[a-zA-Z]+\z/, size: (2..64), blacklist: ->(v : String) { v.in?(BLACKLIST) }
    validate :age, range: (13..150)
  end

  test "works" do
    e = Example.from_json(%[{"name": "Admin", "age": 16}])
    v = ExampleValidator.new

    p v.call(e)
  end
end
