# This is so you can write your own reporters
module Lacerda
  class Reporter
    def initialize(options = {})
    end

    def check_publishing
      # Called before all publishers are iterated to check if they satisfy
      # their consumers.
    end

    def check_publisher(publishing_service)
      # Called before one single publisher is checked against its consumers
    end


    def object_publish_specification_errors(consumed_object, errors)
      # Called after a consumed object's specification has been checked against
      # the publisher's specification of that object. It returns an array of
      # errors
    end

    def check_consuming
      # Called before all consumers' consumed objects are iterated to make
      # sure they have a publisher that meets their specification.
    end

    def check_consumer(consuming_service)
      # Called before all consumed objects are iterated
    end

    def object_publisher_existing(consumed_object, is_published)
      # Called after a consumed object was inspected (does a publish specification
      # for this object exist?)
    end

    def result(errors)
      # Called when everything is done with an array of errors. If that array
      # is empty, go ahead and assume all specifications are valid
    end
  end
end
