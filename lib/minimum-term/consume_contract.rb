require 'minimum-term/contract'

module MinimumTerm
  class ConsumeContract < MinimumTerm::Contract
    def object_description_class
      MinimumTerm::ConsumedObject
    end

    def scoped_schema(service)
      filtered_schema = schema.clone
      schema['definitions'].select! do |k|
        k.underscore.start_with?(service.name.underscore+MinimumTerm::SCOPE_SEPARATOR)
      end
      filtered_schema
    end
  end
end
