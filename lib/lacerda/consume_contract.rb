require 'lacerda/contract'

module Lacerda
  class ConsumeContract < Lacerda::Contract
    def object_description_class
      Lacerda::ConsumedObject
    end

    def scoped_schema(service)
      service_name_prefix = Lacerda.underscore(service.name + Lacerda::SCOPE_SEPARATOR)

      # Poor man's deep clone: json 🆗 🆒
      filtered_schema = JSON.parse(schema.to_json)
      filtered_schema['definitions'].select! do |k|
        Lacerda.underscore(k).start_with?(service_name_prefix)
      end
      filtered_schema
    end

    def object(name)
      underscored_name = Lacerda.underscore(name)
      schema = @schema[:definitions][underscored_name]
      raise Lacerda::Service::InvalidObjectTypeError.new(underscored_name) unless schema
      Lacerda::ConsumedObject.new(service, name, schema)
    end
  end
end
