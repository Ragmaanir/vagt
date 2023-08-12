class Vagt::Violation
  alias Value = String | Int32 | Bool

  NONE = [] of Violation

  getter name : String
  getter attributes : Hash(String, Value)

  def initialize(@name, @attributes = {} of String => Value)
  end
end
