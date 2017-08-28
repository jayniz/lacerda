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
        next if o.publisher_name.blank?
        publisher.blank? or o.publisher == publisher
      end
    end

    def publishes?(object_name)
      @publish.object?(object_name.to_s)
    end

    def consumes?(object_name)
      @consume.object?(object_name.to_s)
    end

    def consumes_from?(service_name, object_name)
      @consume.object?([service_name, object_name].join(Lacerda::SCOPE_SEPARATOR))
    end

    def published_objects
      @publish.objects
    end

    def satisfies?(service, reporter = nil)
      Lacerda.validate_reporter(reporter)
      @publish.satisfies?(service, reporter)
    end

    def satisfies_consumers?(options = {})
      reporter = Lacerda.validate_reporter(options.fetch(:reporter, nil))

      @errors = {}
      consumers.each do |consumer|
        @publish.satisfies?(consumer, reporter)
        next if @publish.errors.empty?
        @errors["#{name} -> #{consumer.name}"] = @publish.errors
      end
      @errors.empty?
    end

    def validate_object_to_publish(type, data, scoped: true)
      validate_object_to_publish!(type, data, scoped: true)
      true
    rescue
      false
    end

    def validate_object_to_publish!(type, data, scoped: true)
      object_description = @publish.object(type, scoped: scoped)
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

    def consume_object_from(service_name, type, data)
      consume_object([service_name, type].join(Lacerda::SCOPE_SEPARATOR), data)
    end

    def consume_object(type, data)
      object_description = @consume.object(type)
      Blumquist.new(schema: object_description.schema, data: data)
    end

    private

    def load_contracts
      @publish = Lacerda::PublishSpecification.new(self, File.join(@data_dir, "publish.schema.json"))
      @consume = Lacerda::ConsumeSpecification.new(self, File.join(@data_dir, "consume.schema.json"))
    end
  end
end
