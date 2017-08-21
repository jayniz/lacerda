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
          @attributes = member.dig('attributes', 'typeAttributes') || []
          @is_required = @attributes.include?('required')
          @type = Type.new(@content['value'], @is_required)
          @scope = scope
        end

        def required?
          @is_required
        end

        def spec
            spec = {}
            # We might have a description
            spec['description'] = @description
            spec.merge!(@type.to_hash)
            # add the type of the array objects (if it is an array)
            spec['items'] = @type.array_type
              # If it's an object, we need recursion
            if @type.object?
              spec['properties'] = {}
              data_structure = DataStructure.new('tmp', [@content['value']], @scope).to_json
              spec['properties'].merge!(data_structure['properties'])
            end
            spec
        end
      end
    end
  end
end
