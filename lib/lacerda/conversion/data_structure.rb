
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
      end

      def to_json
        @schema
      end

      private

      def add_description_to_json_schema
        return unless @data['sections']
        description = @data['sections'].select{|d| d['class'] == 'blockDescription' }.first
        return unless description
        @schema['description'] = description['content'].strip
      end

      def add_properties_to_json_schema
        return unless @data['sections']
        return unless @data['sections'].length > 0
        members = @data['sections'].select{|d| d['class'] == 'memberType' }.first['content'].select{|d| d['class'] == 'property' }

        # Iterate over each property
        members.each do |s|

          # Pluck some things out of the AST
          content = s['content']
          type_definition = content['valueDefinition']['typeDefinition']
          type = type_definition['typeSpecification']['name']
          attributes = type_definition['attributes'] || []
          is_required = attributes.include?('required')

          # Prepare the json schema fragment
          spec = {}
          name = Lacerda.underscore(content['name']['literal'])

          # This is either type: primimtive or a oneOf { $ref: reference_name }
          spec.merge!(primitive_or_oneOf(type, is_required))

          # We might have a description
          spec['description'] = content['description']

          # If it's an array, we need to pluck out the item types
          if type == 'array'
            nestedTypes = type_definition['typeSpecification']['nestedTypes']
            spec['items'] = array_items(nestedTypes)

          # If it's an object, we need recursion
          elsif type == 'object'
            spec['properties'] = {}
            content['sections'].select{|d| d['class'] == 'memberType'}.each do |data|
              data_structure = DataStructure.new('tmp', content, @scope).to_json
              spec['properties'].merge!(data_structure['properties'])
            end
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
          primitive(type, false)
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
        {'$ref' => "#/definitions/#{self.class.scope(@scope, type['literal'])}" }
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
