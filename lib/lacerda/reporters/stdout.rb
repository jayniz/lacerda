# coding: utf-8
module Lacerda
  module Reporters
    class Stdout < Lacerda::Reporter
      def initialize(options = {})
        @verbose = options.fetch(:verbose, true)
        @io = options.fetch(:output, $stdout)
      end
  
      def check_publishing
      end
  
      def check_publisher(publisher)
        @io.print "\n#{publisher.name.camelize} satisfies: " if @verbose
      end
  
      def consume_specification_satisfied(consumer, is_valid)
        if is_valid
          @io.print "#{consumer.name.camelize.green} " if @verbose
        else
          @io.print "#{consumer.name.camelize.red} " if @verbose
        end
      end
  
      def check_consuming
        @io.print "\n" if @verbose
      end
  
      def check_consumer(consuming_service)
      end
  
      def object_publisher_existing(consumed_object, is_published)
      end

      def result(errors)
        if errors.blank?
          @io.puts "All contracts valid 🙌".green if @verbose
        else
          @io.puts JSON.pretty_generate(errors)
          @io.puts "#{errors.length} contract violations".red
        end
      end
    end
  end
end
