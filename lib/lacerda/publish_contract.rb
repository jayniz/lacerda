require 'lacerda/contract'

module Lacerda
  class PublishContract < Lacerda::Contract

    def errors
      return [] unless @comparator
      @comparator.errors
    end

    def satisfies?(consumer)
      @comparator = Compare::JsonSchema.new(@schema)
      @comparator.contains?(consumer.consume.scoped_schema(service), consumer.name)
    end

    def object(name)
      scoped_name = name.to_s.underscore

      # Add our own prefix automatically if necessary
      unless scoped_name.start_with?(service.name.underscore)
        scoped_name = [service.name.underscore, scoped_name].join(Lacerda::SCOPE_SEPARATOR)
      end

      schema = @schema[:definitions][scoped_name]
      raise Lacerda::Service::InvalidObjectTypeError.new(scoped_name) unless schema
      Lacerda::PublishedObject.new(service, scoped_name, schema)
    end

    private

    def object_description_class
      Lacerda::PublishedObject
    end
  end
end