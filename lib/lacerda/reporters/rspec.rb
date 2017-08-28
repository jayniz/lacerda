require 'active_support/core_ext/object/try'

module Lacerda
  module Reporters
    class RSpec < Lacerda::Reporter
      def initialize(group = RSpec.describe("Lacerda infrastructure contract validation"))
        @group = group
      end

      def consume_specification_satisfied(consumer, is_valid)
        @current_publisher.it "satisfies #{consumer.name}" do
          expect(is_valid).to be true
        end
      end

      # errors is a hash with the following structure:
      #   { "publisher_name -> consumer_name" => [
      #      { :error => :ERR_MISSING_DEFINITION,
      #        :message =>"Some text",
      #        :location => 'consumer_name/publisher_name::object_name
      #      }]
      #   }
      def consume_specification_errors(consumer, errors)
        error_messages = errors.map do |error|
          "- #{error[:error]} in #{error[:location]}: #{error[:message]}"
        end
        msg = "expected #{@current_publisher.description} to satisfy "\
              "#{consumer.name} but found these errors:\n"\
              "  #{error_messages.join("\n")}"
        @current_publisher.it "satisfies #{consumer.name}" do
          expect(error_messages).to be_empty, msg
        end
      end

      def check_publishing
        @current_consumer.try(:run)
        @publish_group = @group.describe("publishers")
      end

      def check_publisher(service)
        @current_publisher = @publish_group.describe(service.try(:name))
      end

      def check_consuming
        @current_publisher.try(:run)
        @consume_group = @group.describe("consumers")
      end

      def check_consumer(service)
        @current_consumer.try(:run)
        @current_consumer = @consume_group.describe("#{service.try(:name)} consuming")
      end

      def object_publisher_existing(object, valid)
        @current_consumer.it "#{object.name} from #{object.try(:publisher).try(:name)}" do
          expect(valid).to be true
        end
      end

      def result(errors)
      end

    end
  end
end
