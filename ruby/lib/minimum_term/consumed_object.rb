require 'minimum_term/object_description'

module MinimumTerm
  class ConsumedObject < MinimumTerm::ObjectDescription

    def publisher
      i = @scoped_name.index(MinimumTerm::SCOPE_SEPARATOR)
      return @defined_in_service unless i > 0
      @defined_in_service.infrastructure.services[@scoped_name[0...i].underscore.to_sym]
    end

    def consumer
      @defined_in_service
    end
  end
end
