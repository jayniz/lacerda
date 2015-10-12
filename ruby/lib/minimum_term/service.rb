module MinimumTerm
  # Models a service and its published objects as well as consumed
  # objects. The app itself is part of an Infrastructure
  class Service
    attr_reader :publish, :consume, :name

    def initialize(data_dir)
      @data_dir = data_dir
      @name = File.basename(data_dir).underscore
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
      @publish = MinimumTerm::Contract.new(self, File.join(@data_dir, "publish.schema.json"))
      @consume = MinimumTerm::Contract.new(self, File.join(@data_dir, "consume.schema.json"))
    end
  end
end
