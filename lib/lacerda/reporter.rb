# This is so you can write your own reporters
module Lacerda
  class Reporter

    def check_publishing
      # Called before all publishers are iterated to check if they satisfy
      # their consumers.
    end

    def check_publisher(publishing_service)
      # Called before one single publisher is checked against its consumers
    end

    def object_publish_specification_valid(consumed_object, is_valid)
      # Called after a consumed object's specification has been checked against
      # the publisher's specification of that object.
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
  end
end
