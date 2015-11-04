module Lacerda
  module Compare
    class JsonSchema
      ERRORS = {
        :ERR_ARRAY_ITEM_MISMATCH  => "The items in the published array don't match the consumer's specification.",
        :ERR_MISSING_DEFINITION   => "The publish specification is missing a type defined in esothe consumer's specification.",
        :ERR_MISSING_POINTER      => "A JSON pointer could not be resolved.",
        :ERR_MISSING_PROPERTY     => "The published object is missing a property required by your specification.",
        :ERR_MISSING_REQUIRED     => "The published object has an optional property that you marked as required in your specification.",
        :ERR_MISSING_TYPE_AND_REF => 'A property has to either have a "type" or a "$ref" property.',
        :ERR_TYPE_MISMATCH        => "The published object has a property with a different type than the consumer's specification.",
        :ERR_NOT_SUPPORTED        => 'I don\'t yet know what to do when the consumer\'s specification has a "$ref" defined and the publisher\'s specification has a "type".'
      }

      attr_reader :errors

      def initialize(containing_schema)
        @containing_schema = containing_schema
      end

      def contains?(contained_schema, initial_location = nil)
        @errors = []
        @initial_location = initial_location
        @contained_schema = contained_schema
        definitions_contained?
      end

      private

      def definitions_contained?
        @contained_schema['definitions'].each do |property, contained_property|
          containing_property = @containing_schema['definitions'][property]
          if !containing_property
            _e(:ERR_MISSING_DEFINITION, [@initial_location, property]) 
          else
            schema_contains?(containing_property, contained_property, [property])
          end
        end
        @errors.empty?
      end

      def _e(error, location, extra = nil)
        message = [ERRORS[error], extra].compact.join(": ")
        @errors.push(error: error, message: message, location: location.compact.join("/"))
        false
      end

      def schema_contains?(publish, consume, location = [])

        # We can only compare types and $refs, so let's make
        # sure they're there
        return _e(:ERR_MISSING_TYPE_AND_REF) unless
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
            return _e(:ERR_TYPE_MISMATCH, location, "#{consume['type']} != #{publish['type']}")
          end

        # 2)
        elsif(consume['$ref'] and publish['$ref'])
         resolved_consume = resolve_pointer(consume['$ref'], @contained_schema)
         resolved_publish = resolve_pointer(publish['$ref'], @containing_schema)
         return schema_contains?(resolved_publish, resolved_consume, location)

        # 3)
        elsif(consume['type'] and publish['$ref'])
          if resolved_ref = resolve_pointer(publish['$ref'], @containing_schema)
            return schema_contains?(resolved_ref, consume, location)
          else
            return _e(:ERR_MISSING_POINTER, location, publish['$ref'])
          end

        # 4)
        elsif(consume['$ref'] and publish['type'])
          return _e(:ERR_NOT_SUPPORTED, location)
        end

        # Make sure required properties in consume are required in publish
        consume_required = consume['required'] || []
        publish_required = publish['required'] || []
        missing = (consume_required - publish_required)
        return _e(:ERR_MISSING_REQUIRED, location, missing.to_json) unless missing.empty?

        # We already know that publish and consume's type are equal
        # but if they're objects, we need to do some recursion
        if consume['type'] == 'object'
          consume['properties'].each do |property, schema|
            return _e(:ERR_MISSING_PROPERTY, location, property) unless publish['properties'][property]
            return false unless schema_contains?(publish['properties'][property], schema, location + [property])
          end
        end

        if consume['type'] == 'array'
          sorted_publish = publish['items'].sort
          consume['items'].sort.each_with_index do |item, i|
            next if schema_contains?(sorted_publish[i], item)
            return _e(:ERR_ARRAY_ITEM_MISMATCH, location)
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
