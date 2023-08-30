require "./errors"
require "./value_validator"
require "./validated"

module Vagt::Validator(T)
  annotation ValidatorMethod
  end

  NO_OPTIONS = "No validation options specified. If you want to ignore a field, use the 'ignore' macro."

  macro ignore(prop)
    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_{{prop.id}}(object : T) : Array(Vagt::Error)?
    end
  end

  macro validate_array(prop, **options)
    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_array_{{prop.id}}(object : T) : Array(Vagt::Error)?
      {% begin %}
        array = object.{{prop.id}}

        {% name, type, opts = T::FIELDS[prop.id.stringify] %}

        nested = {} of Int32 => (Vagt::ObjectError | Array(Vagt::Error))

        {% nested_type = type.resolve.type_vars.first %}

        # TODO: compile time error when invalid options passed
        {% if [String, Bool].includes?(nested_type) || nested_type < Number %}
          array.each_with_index do |value, i|
            errors = [] of Vagt::Error

            {% for k, val in options %}
              errors += Vagt::DEFAULT_VALIDATORS[:{{k}}].call({{val}}, value)
            {% end %}

            nested[i] = errors if errors.any?
          end
        {% else %}
          {% if w = options[:with] %}
            val = {{w}}.new
          {% elsif nested_type < Vagt::Validated %}
            val = {{nested_type}}.default_validator.new
          {% else %}
            {% raise "#{T}.validate_array needs a validator or the validated type needs a default validator" %}
          {% end %}

          array.each_with_index do |value, i|
            if errors = val.call(value)
              nested[i] = errors
            end
          end
        {% end %}

        return [Vagt::ArrayError.new(nested)] of Vagt::Error if nested.any?
      {% end %}
    end
  end

  macro validate_association(prop, **options)
    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_association_{{prop.id}}(object : T) : Array(Vagt::Error)?
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

      err = val.call(value)
      [err] of Vagt::Error if err
    end
  end

  macro validate(prop, **options)
    {% raise "#{@type}.#{prop}: " + NO_OPTIONS if options.empty? %}

    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_{{prop.id}}(object : T) : Array(Vagt::Error)?
      {% begin %}
        value = object.{{prop.id}}

        {% name, type, opts = T::FIELDS[prop.id.stringify] || raise("Field not found: #{prop}") %}

        res = [] of Vagt::Error

        {% for k, val in options %}
          res += Vagt::DEFAULT_VALIDATORS[:{{k}}].call({{val}}, value)
        {% end %}

        # puts "#{object.class}: validate {{prop.id}} => #{res.size}"

        return res if res.any?
      {% end %}
    end
  end

  macro included
    {% verbatim do %}
      macro finished
        {% verbatim do %}
          def self.call(o : T)
            new.call(o)
          end

          def call(o : T) : Vagt::ObjectError?
            {% begin %}
              {%
                field_names = T::FIELDS.map { |k, v| v[0] }
                validator_methods = @type.methods.select { |m| m.annotation(ValidatorMethod) }
                validated_fields = validator_methods.map { |m| m.annotation(ValidatorMethod)[:field].id }
                unvalidated = field_names - validated_fields
                raise "#{@type}: Missing validation for fields: #{unvalidated.splat}" unless unvalidated.empty?
              %}

              res = Hash(String, Array(Vagt::Error)).new

              {% for m in validator_methods %}
                {% ann = m.annotation(ValidatorMethod) %}
                r = {{m.name}}(o)

                field = {{ann[:field]}}
                if r
                  res[field] ||= [] of Vagt::Error
                  res[field] += r
                end
              {% end %}

              Vagt::ObjectError.new(res) if res.any?
            {% end %}
          end
        {% end %}
      end
    {% end %}
  end
end
