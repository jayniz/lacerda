require 'active_support/core_ext/object/try'

module Lacerda
  module Reporters
    class RSpec < Lacerda::Reporter
      def initialize(group = RSpec.describe("Lacerda infrastructure contract validation"))
        @group = group
      end

      def check_publishing
        @publish_group = @group.describe("publishers")
      end

      def check_publisher(service)
        @current_publisher.try(:run)
        @current_publisher = @publish_group.describe(service.name)
      end

      def object_publish_specificaiton_valid(object, valid)
        @current_publisher.it "-> #{object.consumer.name}" do
          expect(valid).to be true
        end
      end

      def check_consuming
        @current_publisher.try(:run)
        @consume_group = @group.describe("consumers")
      end

      def check_consumer(service)
        @current_consumer.try(:run)
        @current_consumer = @consume_group.describe("#{service.name} consuming")
      end

      def object_publisher_existing(object, valid)
        @current_consumer.it "#{object.name} from #{object.publisher.name}" do
          expect(valid).to be true
        end
      end

      def result(errors)
        @current_consumer.try(:run)
        @group.run
      end

    end
  end
end
