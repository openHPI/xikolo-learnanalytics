class ApplicationDecorator < Draper::Decorator
  def export(*fields, **opts)
    export = extract fields.flatten
    export.as_json opts
  end

  private

  def extract(fields)
    fields.each_with_object({}) do |field, hash|
      case field
        when Symbol, String
          hash[field] = send field
        when Hash
          field.each_pair {|name, mth| hash[name] = send mth }
      end
    end
  end

  class << self
    def delegate(name, as: name, to: :model)
      class_eval <<-CODE, __FILE__, __LINE__
       def #{name}; #{to}.#{as}; end
      CODE
    end
  end
end