module MinimumTerm
  # Models a service and its published objects as well as consumed
  # objects. The app itself is part of an Infrastructure
  class Service
    attr_reader :publish, :consume, :name

    def initialize(name)
      @name = name
      load_contracts
    end

    def dependant_on
      consumed_objects.map(&:service).uniq.sort
    end

    def consumed_objects
      @consume.objects
    end

    private

    def load_contracts
      path = File.join(MinimumTerm::Contract::DIR, @name)
      @publish = MinimumTerm::Contract.new(@name, File.join(path, "publish.schema.json"))
      @consume = MinimumTerm::Contract.new(@name, File.join(path, "consume.schema.json"))
    end
  end
end
