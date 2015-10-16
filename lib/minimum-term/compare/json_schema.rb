module MinimumTerm
  module Compare
    class JsonSchema
      ERRORS = {
        :ERR_ARRAY_ITEM_MISMATCH => '',
        :ERR_MISSING_DEFINITION  => '',
        :ERR_MISSING_POINTER     => '',
        :ERR_MISSING_PROPERTY    => '',
        :ERR_MISSING_REQUIRED    => '',
        :ERR_MISSING_TYPE        => '',
        :ERR_TYPE_MISMATCH       => '',
        :ERR_NOT_SUPPORTED       => ''
      }

      attr_reader :errors

      def initialize(containing_schema)
        @containing_schema = containing_schema
      end

      def contains?(contained_schema, pry = false)
        @errors = []
        @contained_schema = contained_schema
        definitions_contained?
      end

      private

      def definitions_contained?
        @contained_schema['definitions'].each do |property, contained_property|
          containing_property = @containing_schema['definitions'][property]
          return _e(:ERR_MISSING_DEFINITION) unless containing_property
          return false unless schema_contains?(containing_property, contained_property)
        end
        true
      end

      def _e(error)
        @errors.push(error: error, message: ERRORS[error])
        false
      end

      def schema_contains?(publish, consume)

        # We can only compare types and $refs, so let's make
        # sure they're there
        return _e!(:ERR_MISSING_TYPE) unless
          (consume['type'] or consume['$ref']) and
          (publish['type'] or publish['$ref'])

        # There's four possibilities here:
        #
        # 1) publish and consume have a type defined
        # 2) publish and consume have a $ref defined
        # 3) publish has a $ref defined, and consume an inline object
        # 4) consume has a $ref defined, and publish an inline object
        #    (we don't support this yet, as otherwise couldn't check for
        #    missing definitions, because we could never know if something
        #    specified in the definitions of the consuming schema exists in
        #    the publishing schema as an inline property somewhere).
        if (consume['type'] and publish['type'])
         return _e(:ERR_TYPE_MISMATCH) if consume['type'] != publish['type']
        elsif(consume['$ref'] and publish['$ref'])
         resolved_consume = resolve_pointer(consume['$ref'], @contained_schema)
         resolved_publish = resolve_pointer(publish['$ref'], @containing_schema)
         return schema_contains?(resolved_publish, resolved_consume)
        elsif(consume['type'] and publish['$ref'])
          return _e(:ERR_MISSING_POINTER) unless resolved_ref = resolve_pointer(publish['$ref'], @containing_schema)
          return schema_contains?(resolved_ref, consume)
        elsif(consume['$ref'] and publish['type'])
          return _e(:ERR_NOT_SUPPORTED)
        end

        # Make sure required properties in consume are required in publish
        consume_required = consume['required'] || []
        publish_required = publish['required'] || []
        return _e(:ERR_MISSING_REQUIRED) unless
          (consume_required - publish_required).empty?

        # We already know that publish and consume's type are equal
        # but if they're objects, we need to do some recursion
        if consume['type'] == 'object'
          consume['properties'].each do |property, schema|
            return _e(:ERR_MISSING_PROPERTY) unless publish['properties'][property]
            return false unless schema_contains?(publish['properties'][property], schema)
          end
        end

        if consume['type'] == 'array'
          sorted_publish = publish['items'].sort
          consume['items'].sort.each_with_index do |item, i|
            next if schema_contains?(sorted_publish[i], item)
            return _e(:ERR_ARRAY_ITEM_MISMATCH)
          end
        end

        true
      end

      def resolve_pointer(pointer, schema)
        type = pointer[/\#\/definitions\/([^\/]+)$/, 1]
        return false unless type
        schema['definitions'][type]
      end
    end
  end
end
