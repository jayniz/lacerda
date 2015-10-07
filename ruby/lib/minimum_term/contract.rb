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

    private

    def load_schema(schema_or_file)
      @schema = @schema_or_file if schema_or_file.is_a?(Hash)
      @schema = JSON.parse(open(schema_or_file).read)
    end
  end
end
