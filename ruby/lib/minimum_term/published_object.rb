require 'minimum_term/object_description'

module MinimumTerm
  class PublishedObject < MinimumTerm::ObjectDescription

    def publisher
      @defined_in_service
    end

    def consumer
      @defined_in_service
    end
  end
end
