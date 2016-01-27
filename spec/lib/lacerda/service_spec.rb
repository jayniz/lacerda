require 'spec_helper'

# We're relying on the test services defined in
# spec/support/contracts
describe Lacerda::Service do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:consumer_invalid_property){ $test_infrastructure.services[:invalid_property] }
  let(:consumer_missing_definition){ $test_infrastructure.services[:missing_definition] }
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
        consumer_missing_definition,
        consumer_missing_required
      ].map(&:name)
      expect(publisher.consumers.map(&:name)).to eq consumers
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
      it "knows that it publishes a certain object" do
        expect(publisher.publishes?('Post')).to be true
      end

      it "knows that it doesn't publish a certain object" do
        expect(publisher.publishes?('Automobile')).to be false
      end

      it "complains about an unknokwn type" do
        expect(
          publisher.validate_object_to_publish('unknown_type', {some: :data})
        ).to be false
      end

      it "complains about an unknokwn type with an exception" do
        expect{
          publisher.validate_object_to_publish!('unknown_type', {some: :data})
        }.to raise_error(Lacerda::Service::InvalidObjectTypeError)
      end

      it "accepts a valid object" do
        valid_post = {id: 1, title: 'My title', body: 'Body'}
        expect(
          publisher.validate_object_to_publish('Post', valid_post)
        ).to be true
      end

      it "rejects an valid object with an exception" do
        invalid_post = {id: 'string', title: 'My title'}
        expect{
          publisher.validate_object_to_publish!('Post', invalid_post)
        }.to raise_error(JSON::Schema::ValidationError)
      end
    end

    context "to consume" do
      let(:valid_post) { {id: 1, title: 'My title'} }

      it "knows that it consume a certain object from a service" do
        expect(consumer.consumes_from?('Publisher', 'Post')).to be true
      end

      it "knows that it doesn't consume a certain object from a service" do
        expect(consumer.consumes_from?('NonExistantService', 'Automobile')).to be false
      end

      it "knows that it consume a certain object" do
        expect(consumer.consumes?('Publisher::Post')).to be true
      end

      it "knows that it doesn't consume a certain object" do
        expect(consumer.consumes?('Publisher::Automobile')).to be false
      end

      it "complains about an unknown type" do
        expect(
          consumer.validate_object_to_consume('Publisher::unknown_type', {some: :data})
        ).to be false
      end

      it "complains about an unknokwn type with an exception" do
        expect{
          consumer.validate_object_to_consume!('Publisher::unknown_type', {some: :data})
        }.to raise_error(Lacerda::Service::InvalidObjectTypeError)
      end

      it "accepts a valid object" do
        expect(
          consumer.validate_object_to_consume('Publisher::Post', valid_post)
        ).to be true
      end

      it "rejects an valid object with an exception" do
        invalid_post = {tag: 'string', title: 'My title'}
        expect{
          consumer.validate_object_to_consume!('Publisher::Post', invalid_post)
        }.to raise_error(JSON::Schema::ValidationError)
      end

      it "returns a Blumquist object to consume" do
        schema = consumer.consume.object('Publisher::Post').schema
        expect(Blumquist).to receive(:new).with(schema: schema, data: valid_post).and_return :blumquist
        expect(
          consumer.consume_object('Publisher::Post', valid_post)
        ).to eq :blumquist
      end

      it "returns a Blumquist object to consume with a given service" do
        schema = consumer.consume.object('Publisher::Post').schema
        expect(Blumquist).to receive(:new).with(schema: schema, data: valid_post).and_return :blumquist
        expect(
          consumer.consume_object_from(:publisher, :post, valid_post)
        ).to eq :blumquist
      end
    end

  end
end
