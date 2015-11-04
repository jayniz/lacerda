require 'active_support/core_ext/string'

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
        members = @data['sections'].select{|d| d['class'] == 'memberType' }.first['content'].select{|d| d['class'] == 'property' }
        members.each do |s|
          content = s['content']
          type_definition = content['valueDefinition']['typeDefinition']
          type = type_definition['typeSpecification']['name']

          spec = {}
          name = Lacerda.underscore(content['name']['literal'])

          # This is either type: primimtive or $ref: reference_name
          spec.merge!(primitive_or_reference(type))

          # We might have a description
          spec['description'] = s['description']

          # If it's an array, we need to pluck out the item types
          if type == 'array'
            nestedTypes = type_definition['typeSpecification']['nestedTypes']
            spec['items'] = nestedTypes.map{|t| primitive_or_reference(t) }

          # If it's an object, we need recursion
          elsif type == 'object'
            spec['properties'] = {}
            content['sections'].select{|d| d['class'] == 'memberType'}.each do |data|
              data_structure = DataStructure.new('tmp', content, @scope).to_json
              spec['properties'].merge!(data_structure['properties'])
            end
          end

          @schema['properties'][name] = spec
          if attributes = type_definition['attributes']
            @schema['required'] << name if attributes.include?('required')
          end
        end
      end

      def primitive_or_reference(type)
	return { 'type' => 'object' } if type.blank?

        if PRIMITIVES.include?(type)
          { 'type' => type }
        else
          { '$ref' => "#/definitions/#{self.class.scope(@scope, type['literal'])}" }
        end
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
