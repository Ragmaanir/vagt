require "./spec_helper"

describe Vagt::PropertyValidations do
  class User
    include Vagt::Validated

    schema do
      field name : String
      field age : Int32
    end

    def initialize(@name, @age)
    end
  end

  class UserValidator
    include Vagt::Validator(User)

    BLACKLIST = %w{Admin admin null delete}

    # validate :name, format: /\A[a-zA-Z]+\z/, size: (2..64), blacklist: ->(v : String) { v.in?(BLACKLIST) }
    validate :name, format: /\A[a-zA-Z]+\z/, size: (2..64), blacklist: BLACKLIST
    validate :age, range: (13..150)
  end

  alias V = UserValidator

  def build_user(name = "Toby", age = 20)
    User.new(name, age)
  end

  test "valid" do
    e = V.call(build_user)

    assert e == nil
  end

  test "name blacklisted" do
    e = V.call(build_user("Admin")) || fail

    assert e["name"].map(&.name) == ["blacklist"]
    assert !e.has_key?("age")
  end

  test "name format invalid" do
    e = V.call(build_user("t0b1")) || fail

    assert e["name"].map(&.name) == ["format"]
    assert !e.has_key?("age")
  end

  test "name size invalid" do
    e = V.call(build_user("T")) || fail

    assert e["name"].map(&.name) == ["size"]
    assert !e.has_key?("age")
  end

  test "age range invalid" do
    e = V.call(build_user(age: -1)) || fail

    assert !e.has_key?("name")
    assert e["age"].map(&.name) == ["range"]
  end
end
