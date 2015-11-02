require 'active_support/core_ext/string'
require 'active_support/core_ext/object/try'
require 'blumquist'
require 'lacerda/service/error'

module Lacerda
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
      consumed_objects.map(&:publisher).uniq
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

    def satisfies?(service, reporter = nil)
      Lacerda.validate_reporter(reporter)
      @publish.satisfies?(service, reporter)
    end

    def satisfies_consumers?(options = {})
      reporter = options.fetch(:reporter, nil)
      Lacerda.validate_reporter(reporter)

      verbose = options.fetch(:verbose, false)
      @errors = {}
      print "#{name.camelize} satisfies: " if verbose
      consumers.each do |consumer|
        @publish.satisfies?(consumer, reporter)
        if @publish.errors.empty?
          print "#{consumer.name.camelize.green} "if verbose
          next
        end
          print "#{consumer.name.camelize.red} "if verbose
        @errors["#{name} -> #{consumer.name}"] = @publish.errors
      end
      print "\n" if verbose
      @errors.empty?
    end

    def validate_object_to_publish(type, data)
      validate_object_to_publish!(type, data)
      true
    rescue
      false
    end

    def validate_object_to_publish!(type, data)
      object_description = @publish.object(type)
      object_description.validate_data!(data)
    end

    def validate_object_to_consume(type, data)
      validate_object_to_consume!(type, data)
      true
    rescue
      false
    end

    def validate_object_to_consume!(type, data)
      object_description = @consume.object(type)
      object_description.validate_data!(data)
    end

    def consume_object(type, data)
      object_description = @consume.object(type)
      Blumquist.new(schema: object_description.schema, data: data)
    end

    private

    def load_contracts
      @publish = Lacerda::PublishContract.new(self, File.join(@data_dir, "publish.schema.json"))
      @consume = Lacerda::ConsumeContract.new(self, File.join(@data_dir, "consume.schema.json"))
    end
  end
end
