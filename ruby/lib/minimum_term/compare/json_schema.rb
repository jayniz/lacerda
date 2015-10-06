require 'fileutils'

module MinimumTerm
  module Compare
    class JsonSchema

      def initialize(publish)
        @publish = JSON.parse(open(publish).read)
      end

      def contains?(consume)
        consume = JSON.parse(open(consume).read)
      end
    end
  end
end