require 'active_support/core_ext/string'

module MinimumTerm
  module Conversion
    class DataStructure
      PRIMITIVES = %w{boolean string number array enum object}

      def self.scope(scope, string)
        [scope, string.to_s].compact.join(MinimumTerm::SCOPE_SEPARATOR).underscore
      end

      def initialize(id, data, scope = nil)
        @scope = scope
        @data = data
        @id = self.class.scope(@scope, id)
        @schema = json_schema_blueprint
        @schema['title'] = @id
        return unless sections
        add_description_to_json_schema
        add_required_to_json_schema
        add_properties_to_json_schema
      end

      def to_json
        @schema
      end

      private

      def add_description_to_json_schema
        description = find_attr(sections, 'blockDescription', 'class')
        return unless description
        @schema['description'] = description['content'].strip
      end

      def add_required_to_json_schema
        @schema['required'] = select_attr(members) do |member|
          required_member?(member)
        end.reduce([]) do |array, member| 
          array << member_name(member)
        end
      end

      def required_member?(member)
        attributes = attr_val(member, *type_definition_path, 'attributes')
        !attributes.nil? and attributes.include?('required')
      end

      def add_properties_to_json_schema
        @schema['properties'].merge!(handle_array_type)
        @schema['properties'].merge!(handle_object_type)
        @schema['properties'].merge!(handle_other_types)
      end

      def handle_array_type
        handle_type(array_type) do |member, spec|
          spec.merge!(nested_types(member))
        end
      end

      def array_type
        select_attr(members, 'array', *type_path)
      end

      def nested_types(member)
        nestedTypes = attr_val(member, *type_definition_path, 
                                       'typeSpecification', 'nestedTypes')
        {'items' => nestedTypes.map{|t| primitive_or_reference(t) }}
      end

      def handle_object_type
        handle_type(object_type) do |member, spec|
          spec['properties'] = sub_sections(member).reduce({}) do |hash, section|
            data_structure = DataStructure.new('tmp', member['content'], @scope).to_json
            hash.merge!(data_structure['properties'])
          end
        end
      end

      def object_type
        select_attr(members, 'object', *type_path)
      end

      def sub_sections(member)
        select_attr(attr_val(member, 
                             'content', 
                             'sections'), 
                    'memberType', 
                    'class')
      end

      def handle_other_types
        handle_type(other_types)
      end

      def other_types
        members - array_type - object_type
      end

      def handle_type(members)
        members.reduce({}) do |hash, member|
          spec = {'description' => member['description']}
          spec.merge!(member_type(member))

          yield(member, spec) if block_given?

          hash.merge!(member_name(member) => spec)
        end
      end

      def member_name(member)
        attr_val(member, 'content', 'name', 'literal').underscore
      end

      def member_type(member)
        type = attr_val(member, *type_path)
        primitive_or_reference(type)
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
          'type' => 'object',
          'properties' => {},
          'required' => []
        }
      end

      def members
        @section ||= find_attr(sections, 'memberType', 'class')
        @members ||= select_attr(@section['content'], 'property', 'class')
      end

      def sections
        @sections ||= @data['sections']
      end

      def type_definition_path
        @type_definition_path ||= ['content', 'valueDefinition', 'typeDefinition']
      end

      def type_path
        @type_path ||= type_definition_path + ['typeSpecification', 'name']
      end

      def select_attr(attrs, val = nil, *args)
        attrs.select do |attr|
          if block_given?
            yield attr
          else
            attr_val(attr, *args) == val
          end
        end
      end

      def find_attr(attrs, val, *args)
        attrs.find do |attr|
          if block_given?
            yield attr
          else
            attr_val(attr, *args) == val
          end
        end
      end

      def attr_val attr, *args
        args.reduce(attr) { |hash, arg| hash[arg] }
      end
    end
  end
end
