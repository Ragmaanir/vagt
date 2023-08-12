module Vagt::Validator(T)
  annotation ValidatorMethod
  end

  OK = Violation::NONE

  macro validate(prop, **options)
    @[ValidatorMethod]
    def validate_{{prop.id}}(object : T) : Array(Vagt::Violation)
      {% begin %}
        value = object.{{prop.id}}

        res = [] of Vagt::Violation

        {% name, type, opts = T::FIELDS[prop.id.stringify] %}

        {% if fmt = options[:format] %}
          {% raise "#{prop} format option requires regex" if !fmt.is_a?(RegexLiteral) %}
          {% raise "#{prop} format option requires String, got #{type}" if !type == String %}

          res << Vagt::Violation.new("format") if !{{fmt}}.matches?(value)
        {% end %}

        {% if size = options[:size] %}
          # { %
          #   if size.is_a?(Expressions)
          #     raise "#{@type}: Expression too complicated (#{size})" if size.expressions.size > 1
          #     size = size.expressions.first
          #   end
          # % }
          {% if size.is_a?(ProcLiteral) %}
            res << Vagt::Violation.new("size") if !{{size}}.call(value.size)
          {% elsif size.is_a?(RangeLiteral) || size.is_a?(ArrayLiteral) || size.is_a?(Expressions) %}
            res << Vagt::Violation.new("size") if !({{size}}).includes?(value.size)
          {% else %}
            {% raise "#{@type}: Invalid size option: #{size} (#{size.class_name})" %}
          {% end %}
        {% end %}

        {% if range = options[:range] %}
          res << Vagt::Violation.new("range") if !({{range}}).includes?(value)
        {% end %}

        {% if l = options[:blacklist] %}
          {% if l.is_a?(ProcLiteral) %}
            res << Vagt::Violation.new("blacklist") if ({{l}}).call(value)
          {% else %}
            res << Vagt::Violation.new("blacklist") if ({{l}}).includes?(value)
          {% end %}
        {% end %}

        res
      {% end %}
    end

    def _validate_format(prop : String, value : String, format : Regex) : Array(Violation)
      format.matches?(value) ? OK : [Vagt::Violation.new("format")]
    end

    def _validate_size(prop : String, value : _, size : Proc(_, Bool)) : Array(Violation)
      size.call(value.size) ? OK : [Vagt::Violation.new("size")]
    end

    def _validate_size(prop : String, value : _, size : Range | Array) : Array(Violation)
      size.includes?(value.size) ? OK : [Vagt::Violation.new("size")]
    end
  end

  macro included
    {% verbatim do %}
      macro finished
        {% verbatim do %}
          def call(o : T)
            {% begin %}
              {%
                field_names = T::FIELDS.map { |k, v| v[0] }
                vms = @type.methods.select { |iv| iv.annotation(ValidatorMethod) }
                unvalidated = field_names - vms.map { |m| m.name.gsub(/\Avalidate_/, "") }
                raise "#{@type}: Missing validation for fields: #{unvalidated.splat}" unless unvalidated.empty?
              %}

              violations = [] of Vagt::Violation

              {% for m in vms %}
                violations += {{m.name}}(o)
              {% end %}

              violations
            {% end %}
          end
        {% end %}
      end
    {% end %}
  end
end
