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
          attributes = get_attr(member, *type_definistion_path, 'attributes')
          !attributes.nil? and attributes.include?('required')
        end.reduce([]) do |array, member| 
           array << content_name_attr(member)
        end
      end

      def add_properties_to_json_schema
        handle_type(array_type) do |content, spec|
          nestedTypes = get_attr(content, 'valueDefinition', 'typeDefinition',
                                          'typeSpecification', 'nestedTypes')
          spec['items'] = nestedTypes.map{|t| primitive_or_reference(t) }
        end

        handle_type(object_type) do |content, spec|
          sections = select_attr(content['sections'], 'memberType', 'class')

          spec['properties'] = sections.reduce({}) do |hash, section|
            data_structure = DataStructure.new('tmp', content, @scope).to_json
            hash.merge!(data_structure['properties'])
          end
        end

        handle_type(other_types)
      end

      def handle_type(members)
        members.each do |member|
          content = member['content']
          type_definition = get_attr(member, *type_definistion_path)

          spec = {'description' => member['description']}

          # This is either type: primimtive or $ref: reference_name
          type = get_attr(member, *type_path)
          spec.merge!(primitive_or_reference(type))

          yield(content, spec) if block_given?

          @schema['properties'][content_name_attr(member)] = spec
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
          'type' => 'object',
          'properties' => {},
          'required' => []
        }
      end

      def type_definistion_path
        ['content', 'valueDefinition', 'typeDefinition']
      end
      def type_path
         type_definistion_path + ['typeSpecification', 'name']
      end

      def content_name_attr(member)
        get_attr(member, 'content', 'name','literal').underscore
      end

      def array_type
        select_attr(members, 'array', *type_path)
      end

      def object_type
        select_attr(members, 'object', *type_path)
      end

      def other_types
        members - array_type - object_type
      end

      def select_attr(arrs, val = nil, *args)
        arrs.select do |arr|
          if block_given?
            yield arr
          else
            get_attr(arr, *args) == val
          end
        end
      end

      def find_attr(arrs, val, *args)
        arrs.find do |arr|
          if block_given?
            yield arr
          else
            get_attr(arr, *args) == val
          end
        end
      end

      def get_attr arr, *args
        args.reduce(arr) { |re, arg| re[arg] }
      end

      def sections
        @sections ||= @data['sections']
      end

      def members
        @section ||= find_attr(sections, 'memberType', 'class')
        @members ||= select_attr(@section['content'], 'property', 'class')
      end
    end
  end
end
