require "./spec_helper"

describe Vagt::ArrayValidations do
  class Item
    include Vagt::Validated

    def self.default_validator
      ItemValidator
    end

    schema do
      field name : String
    end

    def initialize(@name)
    end
  end

  class ItemValidator
    include Vagt::Validator(Item)

    validate :name, format: /\A[a-zA-Z]+\z/
  end

  class User
    include Vagt::Validated

    schema do
      field name : String
      field items : Array(Item)
      field favorite_items : Array(String)
    end

    def initialize(@name, @items, @favorite_items)
    end
  end

  class UserValidator
    include Vagt::Validator(User)

    BLACKLIST = %w{Admin admin null delete}

    validate :name, format: /\A[a-zA-Z]+\z/
    validate_array :items
    validate :favorite_items, size: (0..2)
    validate_array :favorite_items, blacklist: BLACKLIST
  end

  alias V = UserValidator

  def build_user(name = "Toby", items = [] of Item, favorite_items = [] of String)
    User.new(name, items, favorite_items)
  end

  test "valid" do
    e = V.call(build_user)

    assert e == nil
  end

  test "favorite_items size" do
    e = V.call(build_user(favorite_items: ["A", "B", "C"] of String)) || fail

    assert e["favorite_items"].map(&.name) == ["size"]
  end

  test "favorite_items invalid" do
    e = V.call(build_user(favorite_items: ["Admin"] of String)) || fail

    assert e["favorite_items"][0].as(Vagt::ArrayError)[0].as(Array(Vagt::Error)).map(&.name) == ["blacklist"]
  end

  test "items invalid" do
    e = V.call(build_user(items: [Item.new("-.,")])) || fail

    assert e["items"][0].as(Vagt::ArrayError)[0].as(Vagt::ObjectError)["name"].map(&.name) == ["format"]
  end
end
