require 'active_support/core_ext/hash/indifferent_access'

module MinimumTerm
  class Infrastructure
    attr_reader :services

    def initialize(data_dir = MinimumTerm::Contract::DIR)
      @data_dir = data_dir
      load_services
    end

    def contracts_fulfilled?
      publishers.reduce(true) do |memo, publisher|
        memo and publisher.satisfies_consumers?
      end
    end

    def publishers
      services.values.select do |service|
        service.published_objects.length > 0
      end
    end

    def consumers
      services.values.select do |service|
        service.consumed_objects.length > 0
      end
    end

    def convert_all!(keep_intermediary_files = false)
      json_files.each{ |file| FileUtils.rm_f(file) }
      mson_files.each do |file|
        MinimumTerm::Conversion.mson_to_json_schema!(file, keep_intermediary_files)
      end
    end

    def mson_files
      Dir.glob(File.join(@data_dir, "/**/*.mson"))
    end

    def json_files
      Dir.glob(File.join(@data_dir, "/**/*.schema.json"))
    end

    private

    def load_services
      @services = {}.with_indifferent_access
      dirs = Dir.glob(File.join(@data_dir, "*/"))
      dirs.each do |dir|
        service = MinimumTerm::Service.new(self, dir)
        @services[service.name] = service
      end
    end
  end
end
