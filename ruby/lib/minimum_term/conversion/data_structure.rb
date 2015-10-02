require 'active_support/core_ext/string'

module MinimumTerm
  module Conversion
    class DataStructure
      def initialize(data)
        @data = data
      end

      def to_json
        @schema = json_schema_blueprint
        @schema['title'] = @data['name']['literal'].underscore
        add_description_to_json_schema
        add_properties_to_json_schema
        @schema
      end

      private

      def get_member_type(struct, clazz)
        struct.select do |s|
          s['class'] == clazz
        end.map{|d| d['content'] }
      end

      def add_description_to_json_schema
        return unless @data['sections']
        description = get_member_type(@data['sections'], 'blockDescription').first
        return unless description
        @schema['description'] = description.strip
      end

      def add_properties_to_json_schema
        return unless @data['sections']
        member_type = get_member_type(@data['sections'], 'memberType')
        raise "No memberType section found" unless member_type
        get_member_type(member_type.first, 'property').each do |s|
          spec = {}
          name = s['name']['literal'].underscore
          type_definition = s['valueDefinition']['typeDefinition']
          type = type_definition['typeSpecification']['name']

          spec['type'] = type
          nestedTypes = [type_definition['typeSpecification']['nestedTypes']].flatten.compact
          if n = nestedTypes.first
            spec['items'] = {'type' => n['literal'].underscore}
          end


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
