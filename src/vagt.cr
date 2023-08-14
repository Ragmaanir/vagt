require "json"

require "./vagt/validated"
require "./vagt/validator"

module Vagt
  VERSION = {{ `shards version #{__DIR__}`.strip.stringify }}
end
