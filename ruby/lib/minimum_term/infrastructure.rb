require 'active_support/core_ext/hash/indifferent_access'

module MinimumTerm
  class Infrastructure
    attr_reader :services

    def initialize
      load_services
    end

    private

    def load_services
      @services = {}.with_indifferent_access
      dirs = Dir.glob(File.join(MinimumTerm::Contract::DIR, "*/"))
      dirs.each do |dir|
        service_name = File.basename(dir)
        @services[service_name] = MinimumTerm::Service.new(service_name)
      end
    end
  end
end
