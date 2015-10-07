module MinimumTerm
  class Infrastructure
    attr_reader :services

    def initialize
      load_services
    end

    private

    def load_services
      dirs = Dir.glob(File.join(MinimumTerm::Contract::DIR, "*/"))
      @services = dirs.map do |dir|
        MinimumTerm::Service.new(File.basename(dir))
      end
    end
  end
end
