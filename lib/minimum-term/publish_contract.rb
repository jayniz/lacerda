require 'minimum-term/contract'

module MinimumTerm
  class PublishContract < MinimumTerm::Contract

    def errors
      return [] unless @comparator
      @comparator.errors
    end

    def satisfies?(consumer)
      @comparator = Compare::JsonSchema.new(@schema)
      @comparator.contains?(consumer.consume.schema)
    end

    private

    def object_description_class
      MinimumTerm::PublishedObject
    end
  end
end
