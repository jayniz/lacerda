module Lacerda
  module Compare
    class JsonSchema
      ERRORS = {
        :ERR_ARRAY_ITEM_MISMATCH  => "The items in the published array don't match the consumer's specification.",
        :ERR_MISSING_DEFINITION   => "The publish specification is missing a type defined in the consumer's specification.",
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
        properties_contained?
      end

      def schema_contains?(options)
        publish      = options[:publish]
        consume      = options[:consume]
        location     = options[:location] || []

        # We can only compare types and $refs, so let's make
        # sure they're there
        return _e(:ERR_MISSING_TYPE_AND_REF, location) unless
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
        if consume['type'] and publish['type']
          consume_types = ([consume['type']].flatten - ["null"]).sort
          publish_types = [publish['type']].flatten.sort
          if consume_types != publish_types
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
        if [consume['type']].flatten.include?('object')

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
              original_errors = @errors
              @errors = []
              compatible_consume_type_found = false
              consume_types.each do |consume_type|
                next unless publish_type == consume_type or # Because null types are stripped in schema_contains
                            schema_contains?(publish: publish_type, consume: consume_type, location: location + [publish_type])
                compatible_consume_type_found = true
              end
              @errors = original_errors
              return _e(:ERR_MISSING_MULTI_PUBLISH_MULTI_CONSUME, location, publish_type) unless compatible_consume_type_found
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
            return _e(:ERR_MISSING_SINGLE_PUBLISH_MULTI_CONSUME, location, publish['type']) unless compatible_consume_type_found

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
            return _e(:ERR_MISSING_MULTI_PUBLISH_SINGLE_CONSUME, location, incompatible_publish_type) if incompatible_publish_type

          # We don't know how to handle this 😳
          else
            return _e(:ERR_NOT_SUPPORTED, location, "Consume schema didn't have properties defined and publish schema no oneOf")
          end
        end

        if consume['type'] == 'array'
          sorted_publish = publish['items'].sort
          consume['items'].sort.each_with_index do |item, i|
            next if schema_contains?(publish: sorted_publish[i], consume: item)
            return _e(:ERR_ARRAY_ITEM_MISMATCH, location, nil)
          end
        end

        true
      end

      private

      def properties_contained?
        @contained_schema['properties'].each do |property, contained_property|
          resolved_contained_property = data_for_pointer(property, @contained_schema)
          containing_property = @containing_schema['properties'][property]
          if !containing_property
            _e(:ERR_MISSING_DEFINITION, [@initial_location, property], "(in publish.mson)")
          else
            resolved_containing_property = data_for_pointer(
              containing_property,
              @containing_schema
            )
            schema_contains?(
              publish: resolved_containing_property,
              consume: resolved_contained_property,
              location: [property]
            )
          end
        end
        @errors.empty?
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
        if data_or_pointer['type']
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
        schema['definitions'][type]
      end
    end
  end
end
