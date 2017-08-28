require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/try'

module Lacerda
  class Infrastructure
    attr_reader :errors, :data_dir

    def initialize(options)
      @verbose = !!options.fetch(:verbose, false)
      @data_dir = options.fetch(:data_dir)
      @mutex1 = Mutex.new
      @mutex2 = Mutex.new
    end

    def reload
      @services = nil
    end

    def contracts_fulfilled?(reporter = nil)
      reporter = Lacerda.validate_reporter(reporter)

      @mutex1.synchronize do
        @errors = {}

        # Check for incompatibility in published objects
        reporter.try(:check_publishing)
        publishers.each do |publisher|
          reporter.try(:check_publisher, publisher)
          publisher.satisfies_consumers?(verbose: @verbose, reporter: reporter)
          next if publisher.errors.empty?
          @errors.merge! publisher.errors
        end

        # Check for missing publishers
        reporter.try(:check_consuming)
        missing_publishers = {}
        consumers.each do |consumer|
          reporter.try(:check_consumer, consumer)
          consumer.consumed_objects.each do |object|
            if object.publisher
              reporter.try(:object_publisher_existing, object.name, object.publisher.name, true)
              next
            else
              missing_publishers[object.publisher_name.camelize] ||= []
              missing_publishers[object.publisher_name.camelize] << consumer.name.camelize
              reporter.try(:object_publisher_existing, object.name, object.publisher_name.camelize, false)
            end
          end
        end

        # Report missing publishers
        unless missing_publishers.empty?
          missing = []
          missing_publishers.each do |publisher, consumers|
            missing << "#{publisher} (consumed by #{consumers.join(', ')})"
          end
          errors["Missing publishers"] = missing
        end

        reporter.try(:result, @errors)

        @errors.empty?
      end
    end

    def publishers
      services.values.select do |service|
        service.published_objects.length > 0
      end
    end

    def consumers
      services.values.select do |service|
        service.consumed_objects.length > 0
      end
    end

    def convert_all!(keep_intermediary_files = false)
      json_files.each{ |file| FileUtils.rm_f(file) }
      mson_files.each do |file|
        Lacerda::Conversion.mson_to_json_schema!(
          filename: file,
          keep_intermediary_files: keep_intermediary_files,
          verbose: @verbose)
      end
      reload
    end

    def mson_files
      Dir.glob(File.join(@data_dir, "/**/*.mson"))
    end

    def json_files
      Dir.glob(File.join(@data_dir, "/**/*.schema.json"))
    end

    def services
      @mutex2.synchronize do
        return @services if @services
        @services = {}.with_indifferent_access
        dirs = Dir.glob(File.join(@data_dir, "*/"))
        dirs.each do |dir|
          service = Lacerda::Service.new(self, dir)
          @services[service.name] = service
        end
        @services
      end
    end
  end
end
