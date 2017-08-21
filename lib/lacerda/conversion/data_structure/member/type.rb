module Lacerda
  module Conversion
    class DataStructure
      class Member
        class Type
          def initialize(type_definition, is_required, scope)
            @type_definition = type_definition
            @scope = scope
            @type_name = type_definition['element']
            @is_required = is_required
          end

          def object?
            @type_name == 'object'
          end

          # A type is transformed to json schema either as a primitive:
          #     { "type" => ["string"] }
          #     { "type" => ["string", "null"] }
          # Or as a oneOf. $ref are always within a oneOf
          #     {"oneOf"=>[{"$ref"=>"#/definitions/tag"}, {"type"=>"null"}]}
          def to_hash
            if PRIMITIVES.include?(@type_name)
              primitive(@type_name, required?)
            else
              oneOf([@type_name], required?)
            end
          end

          # bui
          # As there are specied types in the array, `nil` should not be a valid value
          # and therefore required should be true.
          def array_type
            return unless array?
            if nested_types.size == 1 && PRIMITIVES.include?(nested_types.first)
              primitive(nested_types.first, true) 
            else
              oneOf(nested_types, true)
            end
          end

          private

          def array?
            @type_name == 'array'
          end

          # A basic type is either a primitive type with exactly 1 primitive type
          #   {'type' => [boolean] }
          # a reference
          #   { '$ref' => "#/definitions/name" }
          # or an object if the type in not there
          #   { 'type' => object }
          # Basic types don't care about being required or not.
          def basic_type(type_name, is_required = required?)
            if PRIMITIVES.include?(type_name)
              primitive(type_name, is_required)
            else
              reference(type_name)
            end
          end

          def oneOf(types, is_required)
            types = types.map { |type_name| basic_type(type_name,is_required) }
            types << { 'type' => 'null' } unless is_required
            {
              'oneOf' => types.uniq
            }
          end

          def reference(type_name)
            {'$ref' => "#/definitions/#{Lacerda::Conversion::DataStructure.scope(@scope, type_name)}" }
          end

          def primitive(type_name, is_required) 
            types = [type_name]
            types << 'null' unless is_required
            if type_name == 'enum'
              enum_values = @type_definition['content'].map { |i| i['content'] }
              { 'type' => types, 'enum' => enum_values }
            else
              { 'type' => types }
            end
          end

          def required?
            @is_required
          end

          def primitive?
            PRIMITIVES.include?(type_name.first)
          end

          def nested_types
            error_msg = "This DataStructure::Member is a #{@type_name}, not "\
              'an array, so it cannot have nested types'
            raise error_msg unless array?
            @type_definition['content'].map{|vc| vc['element'] }.uniq
          end
        end
      end
    end
  end
end
