require 'active_support/core_ext/hash/indifferent_access'
require 'lacerda/published_object'
require 'lacerda/consumed_object'

module Lacerda
  class Specification
    attr_reader :service, :schema

    def initialize(service, schema_or_file)
      @service = service
      load_schema(schema_or_file)
    end

    def objects
      return [] unless @schema[:definitions]
      @schema[:definitions].map do |scoped_name, schema|
        next if !scoped_name.index(SCOPE_SEPARATOR)
        object_description_class.new(service, scoped_name, schema)
      end.compact
    end

    private

    def load_schema(schema_or_file)
      if schema_or_file.is_a?(Hash)
        @schema = schema_or_file
      elsif File.readable?(schema_or_file)
        @schema = JSON.parse(open(schema_or_file).read)
      else
        @schema = {}
      end
      @schema = @schema.with_indifferent_access
    end
  end
end
