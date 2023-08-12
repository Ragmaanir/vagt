module Vagt::Validated
  annotation Field
  end

  macro included
    FIELDS = {} of String => Tuple
  end

  macro schema(&block)
    {{yield.id}}
    complete_schema
  end

  macro field(decl, **options)
    {% FIELDS[decl.var.stringify] = {decl.var, decl.type, options} %}
    @[Field]
    getter {{decl}}
  end

  macro complete_schema
  end
end
