require 'lacerda/object_description'

module Lacerda
  class ConsumedObject < Lacerda::ObjectDescription

    def publisher
      return unless publisher_name
      @defined_in_service.infrastructure.services[publisher_name]
    end

    def publisher_name
      i = @scoped_name.index(Lacerda::SCOPE_SEPARATOR)
      return unless i
      Lacerda.underscore(@scoped_name[0...i])
    end

    def consumer
      @defined_in_service
    end
  end
end
