
module Lacerda
  module Conversion
    class DataStructure
      PRIMITIVES = %w{boolean string number array enum object}

      def self.scope(scope, string)
        # This allows users to enter either
        #
        #     # Message
        #     - id (number, required)
        #     - ...
        #
        # or
        #
        #     # MessageService::Message
        #     - id (number, required)
        #     - ...
        #
        # in their publish.mson specification files. Including the service name in
        # a publish specification is redundant and not necessary, but let's let our
        # friendly users do this if they wish.
        #
        scope = nil if Lacerda.underscore(string.to_s).start_with?(Lacerda.underscore(scope.to_s))

        # Now that this is out of the way, let's put a
        # scope in front and return the string.
        Lacerda.underscore(
          [scope, string.to_s].compact.join(Lacerda::SCOPE_SEPARATOR)
        )
      end

      def initialize(id, data, scope = nil)
        @scope = scope
        @data = data
        @id = self.class.scope(@scope, id)
        @schema = json_schema_blueprint
        @schema['title'] = @id
        add_description_to_json_schema
        add_properties_to_json_schema
        @schema['additionalProperties'] = false
      end

      def to_json
        @schema
      end

      private

      def add_description_to_json_schema
        return unless @data
        description = @data.detect { |c| c.dig('meta', 'description') }
        return unless description
        @schema['description'] = description['meta']['description'].strip
      end

      def add_properties_to_json_schema
        possible_members  = @data&.first&.dig('content')
        return unless possible_members
        # In the case that you create a nested data structure when type == 'object', 
        # the possible_members can be just a Hash, instead of an array
        possible_members = [possible_members] if possible_members.is_a?(Hash)
        members = possible_members.select { |d| d['element'] == 'member' }
        # Iterate over each property
        members.each do |s|

          # Pluck some things out of the AST
          content = s['content']
          type_definition = content['value']
          type = type_definition['element']
          attributes = s.dig('attributes', 'typeAttributes') || []
          is_required = attributes.include?('required')

          # Prepare the json schema fragment
          spec = {}
          name = Lacerda.underscore(content['key']['content'])

          # This is either type: primimtive or a oneOf { $ref: reference_name }
          spec.merge!(primitive_or_oneOf(type, is_required))

          # We might have a description
          spec['description'] = s.dig('meta', 'description')

          # If it's an array, we need to pluck out the item types
          if type == 'array'
            nestedTypes = type_definition['content'].map{|vc| vc['element'] }.uniq
            spec['items'] = array_items(nestedTypes)

          # If it's an object, we need recursion
          elsif type == 'object'
            spec['properties'] = {}
            # The object has a value that will represent a data structure. the data
            # passed to DataStructure normally is an array, but in this case if wouldn't
            # So we have to wrap it if it's not an Array.
            data = [content['value']] unless content['value'].is_a?(Array)
            data_structure = DataStructure.new('tmp', [content['value']], @scope).to_json
            spec['properties'].merge!(data_structure['properties'])
          end

          # Add the specification of this property to the schema
          @schema['properties'][name] = spec

          # Mark the property as required
          @schema['required'] << name if is_required
        end
      end

      # returns the type of an array, given its specified type(s). This will be
      # either exactly one basic type, or a oneOf in case there are 1+ types 
      # or exactly 1 non-basic type. 
      # As there are specied types in the array, `nil` should not be a valid value
      # and therefore required should be true.
      def array_items(types)
        if types.size == 1 && PRIMITIVES.include?(types.first)
          primitive(types.first, true) 
        else
          oneOf(types, true)
        end
      end

      def primitive_or_oneOf(type, is_required)
      	return { 'type' => 'object' } if type.blank?
        if PRIMITIVES.include?(type)
          primitive(type, is_required)
        else
          oneOf([type], is_required)
        end
      end

      # A basic type is either a primitive type with exactly 1 primitive type
      #   {'type' => [boolean] }
      # a reference
      #   { '$ref' => "#/definitions/name" }
      # or an object if the type in not there
      #   { 'type' => object }
      # Basic types don't care about being required or not.
      def basic_type(type)
        return { 'type' => 'object' } if type.blank?
        if PRIMITIVES.include?(type)
          primitive(type, true)
        else
          reference(type)
        end
      end

      def oneOf(types, is_required)
        types = types.map { |type| basic_type(type) }
        types << { 'type' => 'null' } unless is_required
        {
          'oneOf' => types.uniq
        }
      end

      def primitive(type, is_required) 
        types = [type]
        types << 'null' unless is_required
        { 'type' => types }
      end

      def reference(type)
        {'$ref' => "#/definitions/#{self.class.scope(@scope, type)}" }
      end

      def json_schema_blueprint
        {
          "type" => "object",
          "properties" => {},
          "required" => []
        }
      end

    end
  end
end
