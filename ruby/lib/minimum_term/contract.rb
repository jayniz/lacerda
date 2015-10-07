require 'active_support/core_ext/hash/indifferent_access'
require 'minimum_term/object'

module MinimumTerm
  class Contract
    DIR = File.expand_path("../contracts")

    def self.mson_files
      Dir.glob(File.join(DIR, "/**/*.mson"))
    end

    def self.json_files
      Dir.glob(File.join(DIR, "/**/*.json"))
    end


    attr_reader :service, :schema

    def initialize(service, schema_or_file)
      @service = service
      load_schema(schema_or_file)
    end

    def objects
      @schema[:definitions].map do |scoped_name, schema|
        MinimumTerm::Object.new(service, scoped_name, schema)
      end
    end

    private

    def load_schema(schema_or_file)
      if schema_or_file.is_a?(Hash)
        @schema = @schema_or_file
      else
        @schema = JSON.parse(open(schema_or_file).read)
      end
      @schema = @schema.with_indifferent_access
    end
  end
end
