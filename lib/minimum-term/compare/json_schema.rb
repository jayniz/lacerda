module MinimumTerm
  module Compare
    class JsonSchema
      ERRORS = {
        :ERR_ARRAY_ITEM_MISMATCH  => '',
        :ERR_MISSING_DEFINITION   => '',
        :ERR_MISSING_POINTER      => '',
        :ERR_MISSING_PROPERTY     => '',
        :ERR_MISSING_REQUIRED     => '',
        :ERR_MISSING_TYPE_AND_REF => '',
        :ERR_TYPE_MISMATCH        => '',
        :ERR_NOT_SUPPORTED        => ''
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

      def _e(error, meta = {})
        @errors.push({error: error, message: ERRORS[error]}.merge(meta))
        false
      end

      def schema_contains?(publish, consume)

        # We can only compare types and $refs, so let's make
        # sure they're there
        return _e!(:ERR_MISSING_TYPE_AND_REF) unless
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
        #    TODO: check if what I just said makes sense. I'm not sure anymore.
        # Let's go:

        # 1)
        if (consume['type'] and publish['type'])
          if consume['type'] != publish['type']
            return _e(:ERR_TYPE_MISMATCH, types: [consume['type'], publish['type']])
          end

        # 2)
        elsif(consume['$ref'] and publish['$ref'])
         resolved_consume = resolve_pointer(consume['$ref'], @contained_schema)
         resolved_publish = resolve_pointer(publish['$ref'], @containing_schema)
         return schema_contains?(resolved_publish, resolved_consume)

        # 3)
        elsif(consume['type'] and publish['$ref'])
          if resolved_ref = resolve_pointer(publish['$ref'], @containing_schema)
            return schema_contains?(resolved_ref, consume)
          else
            return _e(:ERR_MISSING_POINTER, pointer: publish['$ref'])
          end

        # 4)
        elsif(consume['$ref'] and publish['type'])
          return _e(:ERR_NOT_SUPPORTED)
        end

        # Make sure required properties in consume are required in publish
        consume_required = consume['required'] || []
        publish_required = publish['required'] || []
        missing = (consume_required - publish_required)
        return _e(:ERR_MISSING_REQUIRED, missing: missing) unless missing.empty?

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
