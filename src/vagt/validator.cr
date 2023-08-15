# require "./violation"
# require "./validation_result"
require "./errors"
require "./validated"

module Vagt::Validator(T)
  annotation ValidatorMethod
  end

  macro validate_array(prop, **options)
    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_array{{prop.id}}(object : T) : Vagt::ArrayNode?
      {% begin %}
        value = object.{{prop.id}}

        {% name, type, opts = T::FIELDS[prop.id.stringify] %}

        res = [] of Vagt::Error

        nested = {} of Int32 => Vagt::Node

        {% nested_type = type.resolve.type_vars.first %}

        {% if w = options[:with] %}
          val = {{w}}.new
        {% elsif nested_type < Vagt::Validated %}
          val = value.class.default_validator.new
        {% elsif nested_type == String || nested_type < Number %}
          # TODO: shortcuts
        {% else %}
          {% raise "#{T}.validate_array needs a validator or the validated type needs a default validator" %}
        {% end %}

        # value.each_with_index do |e, i|
        #   if errors = val.call(value)
        #     nested[i] = errors
        #   end
        # end

        return Vagt::ArrayNode.new(res, nested) if res.any? || nested.any?
      {% end %}
    end
  end

  macro validate_association(prop, **options)
    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_association_{{prop.id}}(object : T) : Vagt::ObjectNode?
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

      val.call(value)
    end
  end

  macro validate(prop, **options)
    @[ValidatorMethod(field: "{{prop.id}}")]
    def validate_{{prop.id}}(object : T) : Vagt::PropertyNode?
      {% begin %}
        value = object.{{prop.id}}

        {% name, type, opts = T::FIELDS[prop.id.stringify] %}

        res = [] of Vagt::Error

        {% if fmt = options[:format] %}
          {% raise "#{prop} format option requires regex" if !fmt.is_a?(RegexLiteral) %}
          {% raise "#{prop} format option requires String, got #{type}" if !type == String %}

          res << Vagt::Error.new(value, "format") if !{{fmt}}.matches?(value)
        {% end %}

        {% if size = options[:size] %}
          size = ({{size}})

          {% if size.is_a?(ProcLiteral) %}
            res << Vagt::Error.new(value, "size") if !size.call(value.size)
          {% elsif size.is_a?(RangeLiteral) || size.is_a?(ArrayLiteral) || size.is_a?(Expressions) %}
            res << Vagt::Error.new(value, "size") if !size.includes?(value.size)
          {% else %}
            {% raise "#{@type}: Invalid size option: #{size} (#{size.class_name})" %}
          {% end %}
        {% end %}

        {% if range = options[:range] %}
          res << Vagt::Error.new(value, "range") if !({{range}}).includes?(value)
        {% end %}

        {% if l = options[:blacklist] %}
          l = ({{l}})

          {% if l.is_a?(ProcLiteral) %}
            res << Vagt::Error.new(value, "blacklist") if l.call(value)
          {% else %}
            res << Vagt::Error.new(value, "blacklist") if l.includes?(value)
          {% end %}
        {% end %}

        # puts "#{object.class}: validate {{prop.id}} => #{res.size}"

        return Vagt::PropertyNode.new(res) if res.any?
      {% end %}
    end
  end

  macro included
    {% verbatim do %}
      macro finished
        {% verbatim do %}
          def self.call(o : T) : Vagt::ObjectNode?
            new.call(o)
          end

          def call(o : T) : Vagt::ObjectNode?
            {% begin %}
              {%
                field_names = T::FIELDS.map { |k, v| v[0] }
                validator_methods = @type.methods.select { |m| m.annotation(ValidatorMethod) }
                # validations = @type.methods.select { |m| {m, m.annotation(ValidatorMethod)} }
                validated_fields = validator_methods.map { |m| m.annotation(ValidatorMethod)[:field].id }
                # validated = vms.map { |m| m.name.gsub(/\Avalidate_/, "") }
                unvalidated = field_names - validated_fields
                raise "#{@type}: Missing validation for fields: #{unvalidated.splat}" unless unvalidated.empty?
              %}

              res = Hash(String, Vagt::Node).new

              {% for m in validator_methods %}
                {% ann = m.annotation(ValidatorMethod) %}
                r = {{m.name}}(o)

                field = {{ann[:field]}}
                res[field] = r if r
              {% end %}

              Vagt::ObjectNode.new([] of Vagt::Error, res) if res.any?
            {% end %}
          end
        {% end %}
      end
    {% end %}
  end
end
