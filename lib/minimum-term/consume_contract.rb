require 'minimum-term/contract'

module MinimumTerm
  class ConsumeContract < MinimumTerm::Contract
    def object_description_class
      MinimumTerm::ConsumedObject
    end
  end
end
