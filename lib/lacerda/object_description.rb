# This represents a description of an Object (as it was in MSON and later
# JSON Schema). It can come in two flavors:
#
#   1) A published object
#   2) A consumed object
#
# A published object only refers to one servce:
#
#   - its publisher
#
# However, a consumed object is referring to two services:
#
#   - its publisher
#   - its consumer
#
#
module Lacerda
  class ObjectDescription
    attr_reader :service, :name, :schema
    def initialize(defined_in_service, scoped_name, schema)
      @defined_in_service = defined_in_service
      @scoped_name = scoped_name
      @name = remove_service_from_scoped_name(scoped_name)
      @schema = schema
    end

    private

    def remove_service_from_scoped_name(n)
      n[n.index(Lacerda::SCOPE_SEPARATOR)+1..-1]
    end

  end
end
