require "./spec_helper"

describe Vagt do
  class Item
    include JSON::Serializable
    include Vagt::Validated

    def self.default_validator
      ItemValidator
    end

    schema do
      field name : String
    end
  end

  class ItemValidator
    include Vagt::Validator(Item)

    validate :name, format: /\A[a-zA-Z]+\z/
  end

  class Example
    include JSON::Serializable
    include Vagt::Validated

    schema do
      field name : String
      field age : Int32
      field item : Item
    end
  end

  class ExampleValidator
    include Vagt::Validator(Example)

    BLACKLIST = %w{Admin admin null delete}

    validate :name, format: /\A[a-zA-Z]+\z/, size: (2..64), blacklist: ->(v : String) { v.in?(BLACKLIST) }
    validate :age, range: (13..150)
    validate_association :item
  end

  test "valid" do
    e = Example.from_json(%[{"name": "Toby", "age": 16, "item": {"name": "sword"}}])
    v = ExampleValidator.new

    r = v.call(e)

    assert r.valid?

    assert r.violations.empty?
  end

  test "invalid" do
    e = Example.from_json(%[{"name": "Admin", "age": 16, "item": {"name": ""}}])
    v = ExampleValidator.new

    r = v.call(e)

    assert !r.valid?

    assert r["name"].map(&.name) == ["blacklist"]
    assert !r.has_key?("age")
    assert r["item"].map(&.name) == ["nested"] of String
  end
end

# getter item : Item
# getter items : Array(Item)
# => Array(ValidationResult) ?
# getter items : Array(String)
# => Array(Array(Violation)) ?

# getter thing : String
# => [Violation]

# getter things : Array(String)
# => [[Violation], [Violation]

# getter item : Item
# => [Violation(Nested)]

# getter items : Array(Items)
# => [[Violation(Nested)], [Violation(Nested)]]
