class Vagt::ValidationResult
  alias Violations = Hash(String, Array(Violation) | Violations)

  getter violations : Hash(String, Violations)

  def initialize(@violations)
  end
end
