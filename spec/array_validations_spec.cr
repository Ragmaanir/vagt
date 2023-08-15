require "./spec_helper"

describe Vagt::ArrayValidations do
  class User
    include Vagt::Validated

    schema do
      field name : String
      field items : Array(String)
    end

    def initialize(@name, @items)
    end
  end

  class UserValidator
    include Vagt::Validator(User)

    BLACKLIST = %w{Admin admin null delete}

    validate :name, format: /\A[a-zA-Z]+\z/
    validate :items, size: (1..4)
    validate_array :items
  end

  alias V = UserValidator

  def build_user(name = "Toby", items = ["Sword"] of String)
    User.new(name, items)
  end

  test "valid" do
    e = V.call(build_user)

    assert e == nil
  end

  test "items size" do
    e = V.call(build_user(items: [] of String)) || fail

    assert e["items"].as(ArrayNode)[0].errors.map(&.name) == ["blacklist"]
  end
end
