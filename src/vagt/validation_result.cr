class Vagt::ValidationResult
  # alias Violations = Hash(String, Array(Violation) | Violations)

  getter violations : Hash(String, Array(Violation))

  delegate :[], :[]?, :has_key?, to: violations

  def initialize(@violations)
  end

  def valid?
    !errors?
  end

  def errors?
    !violations.empty?
    # violations.any? { |k, arr|  }
  end
end
