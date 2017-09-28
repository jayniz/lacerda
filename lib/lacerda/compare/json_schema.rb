module Lacerda
  module Compare
    class JsonSchema
      ERRORS = {
        :ERR_ARRAY_ITEM_MISMATCH  => "The items in the published array don't match the consumer's specification.",
        :ERR_MISSING_DEFINITION   => "The publish specification is missing a type defined in the consumer's specification.",
        :ERR_MISSING_POINTER      => "A JSON pointer could not be resolved.",
        :ERR_MISSING_PROPERTY     => "The published object is missing a property required by your specification.",
        :ERR_MISSING_REQUIRED     => "The published object has an optional property that you marked as required in your specification.",
        :ERR_MISSING_TYPE_AND_REF_AND_ONE_OF => 'A property has to either have a "type", "oneOf" or "$ref" property.',
        :ERR_TYPE_MISMATCH        => "The published object has a property with a different type than the consumer's specification.",
        :ERR_NOT_IMPLEMENTED      => "Not implemented.",
        :ERR_NOT_SUPPORTED        => 'I don\'t yet know what to do when the consumer\'s specification has a "$ref" defined and the publisher\'s specification has a "type".'
      }

      attr_reader :errors

      def initialize(containing_schema)
        @containing_schema = containing_schema
        @errors = []
      end

      def contains?(contained_schema, initial_location = nil)
        @errors = []
        @initial_location = initial_location
        @contained_schema = contained_schema
        properties_contained?
      end

      def schema_contains?(options)
        publish      = options[:publish]
        consume      = options[:consume]
        location     = options[:location] || []
        return false unless publish and consume

        # We can only compare types and $refs, so let's make
        # sure they're there
        return _e(:ERR_MISSING_TYPE_AND_REF_AND_ONE_OF, location) unless
          (consume['type'] or consume['$ref'] or consume['oneOf']) and
          (publish['type'] or publish['$ref'] or publish['oneOf'])

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
        if consume['type'] and publish['type']
          consume_types = ([consume['type']].flatten).sort
          publish_types = [publish['type']].flatten.sort
          if !(publish_types - consume_types).blank?
            return _e(:ERR_TYPE_MISMATCH, location, "Consume types #{consume_types.to_json} not compatible with publish types #{publish_types.to_json}")
          end

        # 2)
        elsif consume['$ref'] and publish['$ref']
         resolved_consume = resolve_pointer(consume['$ref'], @contained_schema)
         resolved_publish = resolve_pointer(publish['$ref'], @containing_schema)

         return _e(:ERR_MISSING_POINTER, location, consume['$ref']) unless resolved_consume
         return _e(:ERR_MISSING_POINTER, location, publish['$ref']) unless resolved_publish
         return schema_contains?(publish: resolved_publish, consume: resolved_consume, location: location)

        # 3)
        elsif consume['type'] and publish['$ref']
          if resolved_ref = resolve_pointer(publish['$ref'], @containing_schema)
            return schema_contains?(publish: resolved_ref, consume: consume, location: location)
          else
            return _e(:ERR_MISSING_POINTER, location, publish['$ref'])
          end

        # 4)
        elsif consume['$ref'] and publish['type']
          return _e(:ERR_NOT_SUPPORTED, location, nil)
        end

        # Make sure required properties in consume are required in publish
        consume_required = consume['required'] || []
        publish_required = publish['required'] || []
        missing = (consume_required - publish_required)
        return _e(:ERR_MISSING_REQUIRED, location, missing.to_json) unless missing.empty?

        # We already know that publish and consume's type are equal
        # but if they're objects, we need to do some recursion
        isnt_a_primitive  = [consume['type']].flatten.include?('object') || consume['oneOf'] || publish['oneOf']
        if isnt_a_primitive

          # An object can either be described by its properties
          # like this:
          #
          # (1) { "type": "object", "properties": { "active": { "type": "boolean" } }
          #
          # or by allowing a bunch of other types like this:
          #
          # (2) { "type": "object", "oneOf": [ {"$ref": "#/definitions/foo"}, {"type": "null"} ]
          #
          # So we need to take care of both cases for both "sides"
          # (publish and consume), so 4 cases in total.
          #
          # First, the easy case:
          if consume['properties'] and publish['properties']
            consume['properties'].each do |property, schema|
              return _e(:ERR_MISSING_PROPERTY, location, property) unless publish['properties'][property]
              return false unless schema_contains?(publish: publish['properties'][property], consume: schema, location: location + [property])
            end

          # Now on to the trickier case, both have 'oneOf's:
          #
          # For each possible object type from the publish schema we have
          # to check if we find a compatible type in the consume schema.
          #
          # It's not sufficient to just compare the names of the objects,
          # because they might be different in the publish and consume
          # schemas.
          elsif publish['oneOf'] and consume['oneOf']
            publish_types = publish['oneOf']
            consume_types = [consume['oneOf']].flatten.compact

            # Check all publish types for a compatible consume type
            publish_types.each do |publish_type|
              errors = []
              consume_types.any? do |consume_type|
               errors = compare_sub_types(publish_type, consume_type, location + [publish_type])
               errors.empty?
              end
              if errors.any?
                # As there is only one type in each oneOf, we can give more specific error.
                # TODO: add this to other cases
                if publish_types.size == 1 && consume_types.size == 1
                  @errors.push(*errors)
                else
                  _e(:ERR_MISSING_MULTI_PUBLISH_MULTI_CONSUME, location, publish_type)
                end
                return false
              end
            end

          # Mixed case 1/2:
          elsif consume['oneOf'] and publish['properties']
            consume_types = ([consume['oneOf']].flatten - [{"type" => "null"}]).sort
            compatible_consume_type_found = false
            original_errors = @errors
            @errors = []
            consume_types.each do |consume_type|
              next unless schema_contains?(publish: publish, consume: consume_type, location: location)
              compatible_consume_type_found = true
            end
            @errors = original_errors
            unless compatible_consume_type_found
              return _e(:ERR_MISSING_SINGLE_PUBLISH_MULTI_CONSUME, location, publish['type'])
            end

          # Mixed case 2/2:
          elsif consume['properties'] and publish['oneOf']
            publish_types = ([publish['oneOf']].flatten - [{"type" => "null"}]).sort
            incompatible_publish_type= nil
            original_errors = @errors
            @errors = []
            publish_types.each do |publish_type|
              next if schema_contains?(publish: publish_type, consume: consume, location: location)
              incompatible_publish_type = publish_type
            end
            @errors = original_errors
            if incompatible_publish_type
              return _e(:ERR_MISSING_MULTI_PUBLISH_SINGLE_CONSUME, location, incompatible_publish_type)
            end

          # We don't know how to handle this 😳
          # an object can either have "properties" or "oneOf", if the schema has anything else, we break
          else
            return _e(:ERR_NOT_SUPPORTED, location, "Consume schema didn't have properties defined and publish schema no oneOf")
          end
        end

        if consume['type'] == 'array' && publish['type'] == 'array'
          if !consume['items'].is_a?(Hash) || !publish['items'].is_a?(Hash)
            return _e(:ERR_NOT_IMPLEMENTED, location, "'items' can only be hash (schema)")
          elsif !schema_contains?(publish: publish['items'], consume: consume['items'])
            return _e(:ERR_ARRAY_ITEM_MISMATCH, location, nil)
          end
        end
        true
      end

      private

      def properties_contained?
        # success is used to ensure we have no errors.
        success = @contained_schema['properties'].map do |name, content|
          property_contained?(name, content)
        end.all? {|is_property_contained| is_property_contained }
        success && @errors.empty?
      end

      def property_contained?(property_name, content)
        resolved_contained_property = data_for_pointer(content, @contained_schema)
        containing_property = @containing_schema['properties'][property_name]

        if !containing_property
          return _e(:ERR_MISSING_DEFINITION, [@initial_location, property_name], "(in publish.mson)")
        end

        # Make sure required properties in consume are required in publish
        publish_required = @containing_schema['required'] || []
        consume_required = @contained_schema['required'] || []
        missing = (consume_required - publish_required)
        return _e(:ERR_MISSING_REQUIRED, [property_name], missing.to_json) unless missing.empty?

        resolved_containing_property = data_for_pointer(
          containing_property,
          @containing_schema
        )

        schema_contains?(
          publish: resolved_containing_property,
          consume: resolved_contained_property,
          location: [property_name]
        )
      end

      def _e(error, location, extra = nil)
        message = [ERRORS[error], extra].compact.join(": ")
        @errors.push(error: error, message: message, location: location.compact.join("/"))
        false
      end

      # Resolve pointer data idempotent(ally?). It will resolve
      #
      #     "foobar"
      #
      # or
      #
      #     { "$ref": "#/definitions/foobar" }
      #
      # or
      #
      #     { "type": "whatever", ... }
      #
      # to
      #
      #     { "type" :"whatever", ... }
      #
      def data_for_pointer(data_or_pointer, schema)
        data = nil
        if data_or_pointer['type'] || data_or_pointer['oneOf']
          data = data_or_pointer
        elsif pointer = data_or_pointer['$ref']
          data = resolve_pointer(pointer, schema)
        else
          data = schema['definitions'][data_or_pointer]
        end
        data
      end

      # Looks up a pointer like #/definitions/foobar and return
      # its definition
      def resolve_pointer(pointer, schema)
        type = pointer[/\#\/definitions\/([^\/]+)$/, 1]
        return false unless type
        # TODO: Not so sure if we should raise an error
        # when schema['definitions'] is missing?
        return false unless schema
        return false unless schema['definitions']
        schema['definitions'][type]
      end

      # If you just want to compare two json objects/types,
      # this method wraps them into full schemas, creates a new
      # instance of self and compares
      def compare_sub_types(containing, contained, location)

        resolved_containing = data_for_pointer(containing, @containing_schema)
        resolved_contained  = data_for_pointer(contained,  @contained_schema)

        containing_schema = {
          'definitions' => { 'foo' => resolved_containing},
          'properties' => { 'bar' => { '$ref' => '#/definitions/foo' } }
        }
        comparator = self.class.new(containing_schema)
        comparator.schema_contains?(publish: resolved_containing, consume: resolved_contained)
        comparator.errors
      end
    end
  end
end
