# Represents a DataStructure AST member and 
# helps transforming it into a json schema.
module Lacerda
  module Conversion
    class DataStructure
      class Member
        attr_reader :name

        def self.from_data_structure_content(data_structure_content, scope)
          return [] if data_structure_content.nil?
          # In the case that you create a nested data structure when type == 'object', 
          # the possible_members can be just a Hash, instead of an array
          if data_structure_content.is_a?(Hash)
            data_structure_content = [data_structure_content] 
          end
          members = data_structure_content.select do |d|
            d['element'] == 'member'
          end
          members.map { |member| Member.new(member, scope) }
        end

        def initialize(member, scope)
          @description = member.dig('meta', 'description')
          @content = member['content']
          @name = Lacerda.underscore(@content['key']['content'])
          @type_definition = @content['value']
          @type = @type_definition['element']
          @attributes = member.dig('attributes', 'typeAttributes') || []
          @is_required = @attributes.include?('required')
          @scope = scope
        end

        def required?
          @is_required
        end

        def spec
            spec = {}
            # This is either type: primimtive or a oneOf { $ref: reference_name }
            spec.merge!(primitive_or_oneOf(@type))

            # We might have a description
            spec['description'] = @description

            # If it's an array, we need to pluck out the item types
            if @type == 'array'
              nestedTypes = @type_definition['content'].map{|vc| vc['element'] }.uniq
              spec['items'] = array_items(nestedTypes)

              # If it's an object, we need recursion
            elsif @type == 'object'
              spec['properties'] = {}
              # The object has a value that will represent a data structure. the data
              # passed to DataStructure normally is an array, but in this case if wouldn't
              # So we have to wrap it if it's not an Array.
              data = [@content['value']] unless @content['value'].is_a?(Array)
              data_structure = DataStructure.new('tmp', [@content['value']], @scope).to_json
              spec['properties'].merge!(data_structure['properties'])
            end
            spec
        end

        def primitive_or_oneOf(type)
          return { 'type' => 'object' } if type.blank?
          if PRIMITIVES.include?(type)
            primitive(type)
          else
            oneOf([type])
          end
        end


        # A basic type is either a primitive type with exactly 1 primitive type
        #   {'type' => [boolean] }
        # a reference
        #   { '$ref' => "#/definitions/name" }
        # or an object if the type in not there
        #   { 'type' => object }
        # Basic types don't care about being required or not.
        def basic_type(type, is_required = required?)
          return { 'type' => 'object' } if type.blank?
          if PRIMITIVES.include?(type)
            primitive(type, is_required)
          else
            reference(type)
          end
        end

        def oneOf(types, is_required = required?)
          types = types.map { |type| basic_type(type, is_required) }
          types << { 'type' => 'null' } unless is_required
          {
            'oneOf' => types.uniq
          }
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

        def reference(type)
          {'$ref' => "#/definitions/#{Lacerda::Conversion::DataStructure.scope(@scope, type)}" }
        end

        def primitive(type, is_required = required?) 
          types = [type]
          types << 'null' unless is_required
          { 'type' => types }
        end
      end
    end
  end
end
