require "./spec_helper"

describe Vagt::PropertyValidations do
  class User
    include JSON::Serializable
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
    r = V.call(User.from_json(%[{"name": "Toby", "age": 16}]))

    assert r.valid?
    assert r.violations.empty?
  end

  test "name blacklisted" do
    r = V.call(build_user("Admin"))

    assert !r.valid?

    assert r["name"].map(&.name) == ["blacklist"]
    assert !r.has_key?("age")
  end

  test "name format invalid" do
    r = V.call(build_user("t0b1"))

    assert !r.valid?

    assert r["name"].map(&.name) == ["format"]
    assert !r.has_key?("age")
  end

  test "name size invalid" do
    r = V.call(build_user("T"))

    assert !r.valid?

    assert r["name"].map(&.name) == ["size"]
    assert !r.has_key?("age")
  end

  test "age range invalid" do
    r = V.call(build_user(age: -1))

    assert !r.valid?

    assert !r.has_key?("name")
    assert r["age"].map(&.name) == ["range"]
  end
end
