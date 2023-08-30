require "./spec_helper"

describe Vagt::Error do
  pending "serialize" do
    json = <<-JSON
    {
      "name": "object_invalid",
      "attributes": {},
      "errors": {
        "name": [
          {
            "name": "blacklist",
            "attributes": {}
          }
        ],
        "item": [
          {
            "name": "object_invalid",
            "attributes": {},
            "errors": {
              "name": [
                {
                  "name": "format",
                  "attributes": {}
                }
              ]
            }
          }
        ]
      }
    }
    JSON
  end
end
