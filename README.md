# vagt

Simple validations for objects.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     vagt:
       github: ragmaanir/vagt
   ```

2. Run `shards install`

## Usage

```crystal
require "vagt"

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

  validate :name, format: /\A[a-zA-Z]+\z/, size: (2..64), blacklist: BLACKLIST
  validate :age, range: (13..150)
end

u = User.new("Admin", 300)

e = UserValidator.call(u).not_nil!

assert e["name"].map(&.name) == ["blacklist"]
assert e["age"].map(&.name) == ["range"]

assert e.to_json == <<-JSON
{
  "name": "object_invalid",
  "attributes": {},
  "errors": {
    "name": [
      {
        "name": "blacklist",
        "attributes": {}
      }
    "age": [
      {
        "name": "range",
        "attributes": {}
      }
    ]
  }
}
JSON
```


## Contributing

1. Fork it (<https://github.com/ragmaanir/vagt/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ragmaanir](https://github.com/ragmaanir) - creator and maintainer
