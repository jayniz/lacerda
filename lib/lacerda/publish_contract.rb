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

    private

    def object_description_class
      Lacerda::PublishedObject
    end
  end
end
