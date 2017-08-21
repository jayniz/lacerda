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
        return unless @data
        description = @data.detect { |c| c.dig('meta', 'description') }
        return unless description
        @schema['description'] = description['meta']['description'].strip
      end

      def add_properties_to_json_schema
        members = Member.from_data_structure_content(@data&.first&.dig('content'), @scope)
        # Iterate over each property
        members.each do |member|
          # Add the specification of this property to the schema
          @schema['properties'][member.name] = member.spec
          # Mark the property as required
          @schema['required'] << member.name if member.required?
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
