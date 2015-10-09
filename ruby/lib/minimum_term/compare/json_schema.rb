module MinimumTerm
  module Compare
    class JsonSchema

      def initialize(containing_schema)
        @containing_schema = containing_schema
      end

      def contains?(contained_schema)
        @contained_schema = contained_schema
        definition_contains?(@containing_schema, @contained_schema)
      end

      private

      def definition_contains?(a, b)
        b['definitions'].each do |property, b_schema|
          a_schema = a['definitions'][property]
          return false unless a_schema && schema_contains?(a_schema, b_schema)
        end
        true
      end

      def schema_contains?(publish, consume)

        # We can only compare types and $refs, so let's make
        # sure they're there
        return false unless (consume['type'] && publish['type']) or
                            (consume['$ref'] && publish['$ref'])

        # There's four possibilities here:
        #
        # 1) publish and consume have a type defined
        # 2) publish and consume have a $ref defined
        # 3) publish has a $ref defined, and consume an inline object
        # 4) consume has a $ref defined, and publish an inline object
        if (consume['type'] and publish['type'])
         return false if consume['type'] != publish['type']
        elsif(consume['$ref'] and publish['$ref'])
         return false if consume['$ref'] != publish['$ref']
        # TODO 3 and 4
        end

        # Make sure required properties in consume are required in publish
        consume_required = consume['required'] || []
        publish_required = publish['required'] || []

        return false unless (consume_required - publish_required).empty?

        # We already know that publish and consume's type are equal
        # but if they're objects, we need to do some recursion
        if consume['type'] == 'object'
          consume['properties'].each do |property, schema|
            return false unless publish['properties'][property]
            return false unless schema_contains?(publish['properties'][property], schema)
          end
        end

        if consume['type'] == 'array'
          consume['items'].each_with_index do |item, i|
            return false unless schema_contains?(publish['items'][i], item)
          end
        end
        # TODO: Check if it is $ref instead of type

        true
      end
    end
  end
end
