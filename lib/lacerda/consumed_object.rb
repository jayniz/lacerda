require 'lacerda/object_description'

module Lacerda
  class ConsumedObject < Lacerda::ObjectDescription

    def publisher
      i = @scoped_name.index(Lacerda::SCOPE_SEPARATOR)
      return @defined_in_service unless i
      @defined_in_service.infrastructure.services[@scoped_name[0...i].underscore.to_sym]
    end

    def consumer
      @defined_in_service
    end
  end
end
