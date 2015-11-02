module Lacerda
  module Reporters
    class Stdout
      def initialize(options = {})
        @verbose = options.fetch(:verbose)
      end
  
      def check_publishing
        # Called before all publishers are iterated to check if they satisfy
        # their consumers.
      end
  
      def check_publisher(publisher)
        print "#{publisher.name.camelize} satisfies: " if @verbose
      end
  
      def consume_specification_satisfied(consumer, is_valid)
        if is_valid
          print "#{consumer.name.camelize.green} " if @verbose
        else
          print "#{consumer.name.camelize.red} " if @verbose
        end
      end
  
      def check_consuming
        print "\n" if @verbose
      end
  
      def check_consumer(consuming_service)
        # Called before all consumed objects are iterated
      end
  
      def object_publisher_existing(consumed_object, is_published)
        # Called after a consumed object was inspected (does a publish specification
        # for this object exist?)
      end
    end
  end
end
