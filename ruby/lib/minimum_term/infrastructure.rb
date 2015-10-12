require 'active_support/core_ext/hash/indifferent_access'

module MinimumTerm
  class Infrastructure
    attr_reader :services

    def initialize(data_dir = MinimumTerm::Contract::DIR)
      @data_dir = data_dir
      load_services
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
        service = MinimumTerm::Service.new(dir)
        @services[service.name] = service
      end
    end
  end
end
