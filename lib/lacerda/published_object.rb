require 'lacerda/object_description'

module Lacerda
  class PublishedObject < Lacerda::ObjectDescription

    def publisher
      @defined_in_service
    end

    def consumer
      @defined_in_service
    end
  end
end
