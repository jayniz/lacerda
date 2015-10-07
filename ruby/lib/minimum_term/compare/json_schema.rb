module MinimumTerm
  module Compare
    class JsonSchema

      def initialize(schema_hash)
        @schema =  schema_hash
      end

      # Methods
      # Public: determine whether a Json Schema 'A' contains the Json Schema 'B' 
      #
      # a - the Hash representation of the main Json Schema
      # b - the Hash representation of the Json Schema to be compared with 'a'
      #
      # returns true if 'b' is contained into 'a'
      def self.schema_definitions_contain?(a, b)
        b['definitions'].each do |property, schema|
          a_schema = a['definitions'][property]
          return false unless schema_contains?(a_schema, b_schema)
        end
        true
      end

      def self.contains?(a,b,diff={})
        schema_definitions_contain?(a,b)
      end

      def self.schema_contains?(publish, consume, foo = {})
        # Make sure type is the same
        return false if consume['type'] != publish['type']

        # Make sure required properties in consume are required in publish
        consume_required = consume['required'] || []
        publish_required = publish['required'] || []
        return false unless (consume_required-publish_required).empty?

        # We already know that publish and consume's type are equal
        # but if they're objects, we need to do some recursion
        if consume['type'] == "object"
          consume['properties'].each do |property, schema|
            next if conflicts?(publish['properties'][property], schema)
            return false
          end
        end

        true
      end
    end
  end
end
