require 'fileutils'

module MinimumTerm
  module Compare
    class JsonSchema

      def initialize(schema_hash)
        @schema =  schema_hash
      end

      # Methods
      # Public: determine whether the current Json Schema contains another one
      # 
      # schema_hash - the Hash representation of the Json Schema to compare with
      # 
      # returns true if the schema_hash is contained into the curren schema 
      def contains?(schema_hash)
        contains_definitions?(schema_hash) && contains_properties?(schema_hash)
      end


      private
      def contains_definitions?(schema_hash)
        (schema_hash['definitions'].keys - @schema['definitions'].keys).empty?
      end

      def contains_properties?(schema_hash)
        schema_hash['definitions'].keys.each do |definition|
          unless contains_required_attributes?(schema_hash, definition)
            false
          end
        end
        true
      end

      def contains_required_attributes?(schema_hash, definition)
        (schema_hash['definitions'][definition]['required'] - @schema['definitions'][definition]['required']).empty?
      end
    end
  end
end