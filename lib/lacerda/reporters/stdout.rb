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
        return unless @verbose
        @consumers = 0
        @consume_errors = 0
        @io.print "\n#{publisher.name.camelize} satisfies: "
      end

      def consume_specification_satisfied(consumer, is_valid)
        @consumers += 1
        if is_valid
          @io.print "#{consumer.name.camelize.green} " if @verbose
        else
          @io.print "#{consumer.name.camelize.red} " if @verbose
          @consume_errors += 1
        end
      end

      def check_consuming
        return unless @verbose
        if @consumers == 0
          @io.print " (no consumers)".yellow + "\n"
        elsif @consume_errors == 0
          @io.print " OK".green
        else
          @io.print " ERROR".red
        end
      end

      def check_consumer(consuming_service)
        return unless @verbose
        @io.print "\nObjects consumed by #{consuming_service.name.camelize}: "
      end

      def object_publisher_existing(consumed_object_name, publisher_name, is_published)
        return unless @verbose
        if is_published
          @io.print ".".green
        else
          @io.print "x".red
        end
      end

      def result(errors)
        return unless @verbose
        if errors.blank?
          @io.puts "\n----------------------"
          @io.puts "All contracts valid 🙌 ".green
        else
          @io.puts "--------------"
          @io.puts "😱  Violations:".red
          @io.puts JSON.pretty_generate(errors)
          @io.puts "#{errors.length} contract violations".red
        end
      end
    end
  end
end
