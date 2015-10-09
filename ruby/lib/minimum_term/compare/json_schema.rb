module MinimumTerm
  module Compare
    class JsonSchema

      # Methods
      # Public: determine whether a Json Schema 'A' definitions contains
      # the Json Schema 'B' definitions
      #
      # a - hash of the main Json Schema
      # b - hash of the Json Schema to be compared with 'a'
      #
      # returns true if 'b' is contained into 'a'
      def self.definition_contains?(a, b)
        b['definitions'].each do |property, b_schema|
          a_schema = a['definitions'][property]
          return false unless a_schema && schema_contains?(a_schema, b_schema)
        end

        true
      end

      def self.schema_contains?(publish, consume)

        # We can only compare types and $refs, so let's make
        # sure they're there
        return false unless (consume['type'] && publish['type']) or
                            (consume['$ref'] && publish['$ref'])

        # Make sure types and $refs are equal
         return false if consume['type'] != publish['type'] or
                         consume['$ref'] != publish['$ref']

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
