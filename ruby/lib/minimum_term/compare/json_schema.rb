module MinimumTerm
  module Compare
    class JsonSchema

      def initialize(schema_hash)
        @schema =  schema_hash
      end

      # Methods
      # Public: determine whether a Json Schema 'A' contains the Json Schema 'B' 
      # 
      # a - the Hash representation of the main Json Schema
      # b - the Hash representation of the Json Schema to be compared with 'a'
      # 
      # returns true if 'b' is contained into 'a' 
      def self.contains?(a, b, diff = {})
        b.keys.each do |k|
          if conflicts?(k, a, b)
            if a[k].is_a?(Hash) && b[k].is_a?(Hash)
              contains?(a[k], b[k], diff)
            else
              diff[k] = [a[k], b[k]]
            end
          end
        end
        diff.empty?
      end

      def self.conflicts?(key, publish, consume)
        # binding.pry
        return true if consume[key]['required'].include?(key) && !publish[key]['required'].include?(key)
        publish[key] != consume[key]
      end
    end
  end
end