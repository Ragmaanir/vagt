require "./violation"
require "./validation_result"
require "./validated"

module Vagt::Validator(T)
  annotation ValidatorMethod
  end

  OK = Violation::NONE

  macro validate_association(prop, **options)
    @[ValidatorMethod]
    def validate_{{prop.id}}(object : T) : Array(Vagt::Violation)
      {% name, type, opts = T::FIELDS[prop.id.stringify] %}

      {% if type.is_a?(Union) && type.types.any? { |t| t < Vagt::Validated } %}
        {% if type.types.any? { |t| t < Vagt::Validated } && type.types.any? { |t| !(t < Vagt::Validated) && t != NilClass } %}
          {% raise "" %}
        {% end %}
      {% end %}

      # puts "#{object.class}: validate_association {{prop.id}}"

      value = object.{{prop.id}}

      {% if w = options[:with] %}
        val = {{w}}.new
      {% else %}
        val = value.class.default_validator.new
      {% end %}

      res = val.call(value)

      if res.errors?
        return [Vagt::NestedViolations.new(value, res)] of Vagt::Violation
      else
        return Vagt::Violation::NONE
      end
    end
  end

  macro validate(prop, **options)
    @[ValidatorMethod]
    def validate_{{prop.id}}(object : T) : Array(Vagt::Violation)
      {% begin %}
        value = object.{{prop.id}}

        {% name, type, opts = T::FIELDS[prop.id.stringify] %}

        res = [] of Vagt::Violation

        {% if fmt = options[:format] %}
          {% raise "#{prop} format option requires regex" if !fmt.is_a?(RegexLiteral) %}
          {% raise "#{prop} format option requires String, got #{type}" if !type == String %}

          res << Vagt::PropertyViolation.new(value, "format") if !{{fmt}}.matches?(value)
        {% end %}

        {% if size = options[:size] %}
          size = ({{size}})

          {% if size.is_a?(ProcLiteral) %}
            res << Vagt::PropertyViolation.new(value, "size") if !size.call(value.size)
          {% elsif size.is_a?(RangeLiteral) || size.is_a?(ArrayLiteral) || size.is_a?(Expressions) %}
            res << Vagt::PropertyViolation.new(value, "size") if !size.includes?(value.size)
          {% else %}
            {% raise "#{@type}: Invalid size option: #{size} (#{size.class_name})" %}
          {% end %}
        {% end %}

        {% if range = options[:range] %}
          res << Vagt::PropertyViolation.new(value, "range") if !({{range}}).includes?(value)
        {% end %}

        {% if l = options[:blacklist] %}
          l = ({{l}})

          {% if l.is_a?(ProcLiteral) %}
            res << Vagt::PropertyViolation.new(value, "blacklist") if l.call(value)
          {% else %}
            res << Vagt::PropertyViolation.new(value, "blacklist") if l.includes?(value)
          {% end %}
        {% end %}

        # puts "#{object.class}: validate {{prop.id}} => #{res.size}"

        return res
      {% end %}
    end

    # def _validate_format(prop : String, value : String, format : Regex) : Array(Violation)
    #   format.matches?(value) ? OK : [Vagt::Violation.new("format")]
    # end

    # def _validate_size(prop : String, value : _, size : Proc(_, Bool)) : Array(Violation)
    #   size.call(value.size) ? OK : [Vagt::Violation.new("size")]
    # end

    # def _validate_size(prop : String, value : _, size : Range | Array) : Array(Violation)
    #   size.includes?(value.size) ? OK : [Vagt::Violation.new("size")]
    # end
  end

  macro included
    {% verbatim do %}
      macro finished
        {% verbatim do %}
          def self.call(o : T) : Vagt::ValidationResult
            new.call(o)
          end

          def call(o : T) : Vagt::ValidationResult
            {% begin %}
              {%
                field_names = T::FIELDS.map { |k, v| v[0] }
                vms = @type.methods.select { |iv| iv.annotation(ValidatorMethod) }
                validated = vms.map { |m| m.name.gsub(/\Avalidate_/, "") }
                unvalidated = field_names - validated
                raise "#{@type}: Missing validation for fields: #{unvalidated.splat}" unless unvalidated.empty?
              %}

              violations = Hash(String, Array(Vagt::Violation)).new

              {% for f in validated %}
                prop = {{f.stringify}}
                r = validate_{{f}}(o)

                if !r.empty?
                  violations[prop] = r
                end
              {% end %}

              Vagt::ValidationResult.new(violations)
            {% end %}
          end
        {% end %}
      end
    {% end %}
  end
end
