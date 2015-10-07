require 'active_support/core_ext/string'

module MinimumTerm
  module Conversion
    class DataStructure
      PRIMITIVES = %w{boolean string number array enum object}

      def self.scope(scope, string)
        [scope, string.to_s].compact.join(MinimumTerm::SCOPE_SEPARATOR).underscore
      end

      def initialize(data, scope = nil)
        @scope = scope
        @data = data['content'].select{|d| d['element'] == 'object' }.first
        @id = self.class.scope(@scope, @data['meta']['id'])
      end

      def to_json
        @schema = json_schema_blueprint
        @schema['title'] = @id
        add_description_to_json_schema
        add_properties_to_json_schema
        @schema
      end

      private

      def get_member_type(struct, clazz, clazz_field = 'class')
        struct.select do |s|
          s[clazz_field] == clazz
        end.map{|d| d['content'] }
      end

      def add_description_to_json_schema
        return unless @data['meta']
        description = @data['meta']['description']
        return unless description
        @schema['description'] = description.strip
      end

      def add_properties_to_json_schema
        return unless @data['content']
        members = @data['content'].select{|d| d['element'] == 'member' }
        members.each do |s|
          spec = {}
          name = s['content']['key']['content'].underscore
          type_definition = s['content']
          type = type_definition['value']['element']

          spec.merge!(primitive_or_reference(type))

          value_content = s['content']['value']['content']
          if value_content.is_a?(Enumerable)
            nestedTypes = value_content.map{|d| d['element'] }.compact
            spec['items'] = nestedTypes.map{|t| primitive_or_reference(t) }
          end

          spec['description'] = s['meta']['description'] if s['meta']

          @schema['properties'][name] = spec
          if attributes = s['attributes']
            @schema['required'] << name if attributes['typeAttributes'].include?('required')
          end
        end
      end

      def primitive_or_reference(type)
        if PRIMITIVES.include?(type)
          { 'type' => type }
        else
          { '$ref' => "#/definitions/#{self.class.scope(@scope, type)}" }
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
