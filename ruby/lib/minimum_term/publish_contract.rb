require 'minimum_term/contract'

module MinimumTerm
  class PublishContract < MinimumTerm::Contract
    private

    def object_description_class
      MinimumTerm::PublishedObject
    end
  end
end
