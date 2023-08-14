class Vagt::ValidationResult
  getter violations : Hash(String, Array(Violation))

  delegate :[], :[]?, :has_key?, to: violations

  def initialize(@violations)
  end

  def valid?
    !errors?
  end

  def errors?
    !violations.empty?
  end
end
