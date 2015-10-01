module MinimumTerm
  module Conversion
    class DataStructure
      def initialize(data)
        @data = data
      end

      def to_json
        @schema = json_schema_blueprint
        @schema['TODOtype'] = @data['name']['literal']
        add_properties_to_json_schema
        @schema
      end

      private

      def get_member_type(struct, clazz)
        struct.select do |s|
          s['class'] == clazz
        end.map{|d| d['content'] }
      end

      def add_properties_to_json_schema
        return unless @data['sections']
        member_type = get_member_type(@data['sections'], 'memberType')
        raise "No memberType section found" unless member_type
        get_member_type(member_type.first, 'property').each do |s|
          type_definition = s['valueDefinition']['typeDefinition']
          spec = {}
          spec['type'] = type_definition['typeSpecification']['name']
          name = s['name']['literal']
          @schema['properties'][name] = spec
          @schema['required'] << name if type_definition['attributes'].include?('required')
        end
      end

      def json_schema_blueprint
        {
          "$schema" => "http://json-schema.org/schema#",
          "type" => "object",
          "properties" => {},
          "required" => []
        }
      end
    end
  end
end
