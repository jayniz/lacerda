require 'spec_helper'

# We're relying on the test services defined in
# spec/support/contracts
describe MinimumTerm::Service do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:consumer_invalid_property){ $test_infrastructure.services[:invalid_property] }
  let(:consumer_missing_required){ $test_infrastructure.services[:missing_required] }

  context "dependencies of services" do
    it "publisher doesn't depend on anybody" do
      expect(publisher.dependant_on.length).to be 0
    end

    it "consumer depends on publisher" do
      expect(consumer.dependant_on.first).to be publisher
    end

    it "publisher knows that consumer depends on it" do
      consumers = [
        consumer,
        consumer_invalid_property,
        consumer_missing_required
      ]
      expect(publisher.dependants).to eq consumers
    end

    it "publisher publishes one object" do
      expect(publisher.published_objects.length).to eq 2
    end

    it "consumed objects filtered by service" do
      expect(consumer.consumed_objects(publisher).length).to eq 1
      expect(consumer.consumed_objects(consumer).length).to eq 0
    end
  end

  context "compatibilities" do
    it "publisher satisfies the consumer" do
      expect(publisher.satisfies?(consumer)).to be true
    end
  end

  context "incompatibilities because of" do
    it "invalid property" do
      expect(publisher.satisfies?(consumer_invalid_property)).to be false
    end

    it "missing required property" do
      expect(publisher.satisfies?(consumer_missing_required)).to be false
    end
  end

end
