require 'json-schema'
require 'active_support/core_ext/hash/indifferent_access'

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
      @schema = schema.with_indifferent_access
      @schema['$schema'] ||= 'http://json-schema.org/draft-04/schema#'
    end

    def validate_data!(data)
      require 'byebug' ; byebug
      JSON::Validator.validate!(@schema, data)
    end

    def validate_data(data)
      JSON::Validator.validate!(@schema, data)
    rescue JSON::Schema::ValidationError
      false
    end

    private

    def remove_service_from_scoped_name(n)
      i = n.index(Lacerda::SCOPE_SEPARATOR)
      return n unless i
      n[i+Lacerda::SCOPE_SEPARATOR.length..-1]
    end

  end
end
