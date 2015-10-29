require 'spec_helper'

# We're relying on the test services defined in
# spec/support/contracts
describe Lacerda::Service do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:consumer_invalid_property){ $test_infrastructure.services[:invalid_property] }
  let(:consumer_missing_required){ $test_infrastructure.services[:missing_required] }

  context "dependencies of services" do
    it "publisher doesn't depend on anybody" do
      expect(publisher.consuming_from.length).to be 0
    end

    it "consumer depends on publisher" do
      expect(consumer.consuming_from.first).to be publisher
    end

    it "publisher knows that consumer depends on it" do
      consumers = [
        consumer,
        consumer_invalid_property,
        consumer_missing_required
      ]
      expect(publisher.consumers).to eq consumers
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
    it "at least one consumer not being satisfied" do
      expect(publisher.satisfies_consumers?).to be false
    end

    it "invalid property" do
      expect(publisher.satisfies?(consumer_invalid_property)).to be false
    end

    it "missing required property" do
      expect(publisher.satisfies?(consumer_missing_required)).to be false
    end
  end

  context "validating objects" do

    context "to publish" do

      it "complains about an unknokwn type" do
        expect(
          publisher.validate_object_to_publish(:unknown_type, {some: :data})
        ).to be false
      end

      it "complains about an unknokwn type with an exception" do
        expect{
          publisher.validate_object_to_publish!(:unknown_type, {some: :data})
        }.to raise_error(Lacerda::Service::InvalidObjectTypeError)
      end

      it "accepts a valid object" do
        valid_post = {id: 1, title: 'My title'}
        expect(
          publisher.validate_object_to_publish(:post, valid_post)
        ).to be true
      end

      it "rejects an valid object with an exception" do
        invalid_post = {id: 'string', title: 'My title'}
        expect{
          publisher.validate_object_to_publish!(:post, invalid_post)
        }.to raise_error(JSON::Schema::ValidationError)
      end

    end

  end
end
