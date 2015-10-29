require 'lacerda/contract'

module Lacerda
  class ConsumeContract < Lacerda::Contract
    def object_description_class
      Lacerda::ConsumedObject
    end

    def scoped_schema(service)
      # Poor man's deep clone: json 🆗 🆒
      filtered_schema = JSON.parse(schema.to_json)
      filtered_schema['definitions'].select! do |k|
        k.underscore.start_with?(service.name.underscore+Lacerda::SCOPE_SEPARATOR)
      end
      filtered_schema
    end

    def object(name)
      schema = @schema[:definitions][name.to_s.underscore]
      raise Lacerda::Service::InvalidObjectTypeError.new(name.to_s.underscore) unless schema
      Lacerda::ConsumedObject.new(service, name, schema)
    end
  end
end
