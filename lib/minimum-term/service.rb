require 'active_support/core_ext/string'

module MinimumTerm
  # Models a service and its published objects as well as consumed
  # objects. The app itself is part of an Infrastructure
  class Service
    attr_reader :infrastructure, :publish, :consume, :name, :errors

    def initialize(infrastructure, data_dir)
      @infrastructure = infrastructure
      @data_dir = data_dir
      @name = File.basename(data_dir).underscore
      load_contracts
    end

    def consuming_from
      consumed_objects.map(&:publisher)
    end

    def consumers
      infrastructure.services.values.select do |service|
        service.consuming_from.include?(self)
      end
    end

    def consumed_objects(publisher = nil)
      @consume.objects.select do |o|
        publisher.blank? or o.publisher == publisher
      end
    end

    def published_objects
      @publish.objects
    end

    def satisfies?(service)
      @publish.satisfies?(service)
    end

    def satisfies_consumers?(verbose: false)
      @errors = {}
      print "#{name.camelize} satisfies: " if verbose
      consumers.each do |consumer|
        @publish.satisfies?(consumer)
        if @publish.errors.empty?
          print "#{consumer.name.camelize}".green if verbose
          next
        end
          print "#{consumer.name.camelize}".red if verbose
        @errors["#{name} -> #{consumer.name}"] = @publish.errors
      end
      print "\n" if verbose
      @errors.empty?
    end

    private

    def load_contracts
      @publish = MinimumTerm::PublishContract.new(self, File.join(@data_dir, "publish.schema.json"))
      @consume = MinimumTerm::ConsumeContract.new(self, File.join(@data_dir, "consume.schema.json"))
    end
  end
end
