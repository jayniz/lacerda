module MinimumTerm
  # Models a service and its published objects as well as consumed
  # objects. The app itself is part of an Infrastructure
  class Service
    attr_reader :contracts, :name

    def initialize(name)
      @name = name
      load_contracts
    end

    private

    def load_contracts
      path = File.join(MinimumTerm::Contract::DIR, @name)
      @publish = MinimumTerm::Contract.new(@name, File.join(path, "publish.schema.json"))
      @consume = MinimumTerm::Contract.new(@name, File.join(path, "consume.schema.json"))
    end
  end
end
