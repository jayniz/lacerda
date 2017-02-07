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
        consumer_missing_required
      ].map(&:name)
      expect(publisher.consumers.map(&:name)).to eq consumers
    end

    it "publisher publishes two objects" do
      expect(publisher.published_objects.map(&:name).sort).to eq ['post', 'tag']
    end

    it "doesn't expose Comment because it's just a local definition" do
      expect(publisher.published_objects.map(&:name).include?("comment")).to be_falsey
    end

    it "consumed objects filtered by service" do
      expect(consumer.consumed_objects(publisher).length).to eq 1
      expect(consumer.consumed_objects(consumer).length).to eq 0
    end
  end

  context "compatibilities" do
    it "publisher satisfies the consumer" do
      result = publisher.satisfies?(consumer)
      expect(result).to be true
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
        valid_post = {id: 1, title: 'My title', body: 'Body', comments: []}
        result = publisher.validate_object_to_publish('Post', valid_post)
        expect(result).to be true
      end

      it "accepts empty strings for required fields" do
        valid_post = {id: 1, title: '', body: '', comments: []}
        result = publisher.validate_object_to_publish('Post', valid_post)
        expect(result).to be true
      end

      it "rejects an valid object with an exception" do
        invalid_post = {id: 'string', title: 'My title'}
        expect{
          publisher.validate_object_to_publish!('Post', invalid_post)
        }.to raise_error(JSON::Schema::ValidationError)
      end

      context '(multitype) arrays' do
        let(:valid_post) do
          { id: 1, title: 'My title', body: 'Body', comments: [] }
        end
        it 'works' do
          post = valid_post.merge(multi_props: [{num: 1}, {nbr: 1,text: '2'}])
          result = publisher.validate_object_to_publish('Post', post)
          expect(result).to be true
        end

        it "works with similar types" do
          similar_properties = [{post_a_id: 1, title: 'a'}, {post_b_id: 1, title: 'b'}]
          post = valid_post.merge(similar_properties: similar_properties)
          expect {
            publisher.validate_object_to_publish!('Post', post)
          }.not_to raise_error(JSON::Schema::ValidationError)
        end

        it 'does not work if two of the types have (some) fields with the same name' do
          post = valid_post.merge(multiple_matches: [{ num: 1, text: "2" }])
          expect {
            publisher.validate_object_to_publish!('Post', post)
          }.to raise_error(JSON::Schema::ValidationError)
        end

        it 'fails if one of the object has 0 required fields' do
          post = valid_post.merge(unrequired: [{num: 1}])
          expect {
            publisher.validate_object_to_publish!('Post', post)
          }.to raise_error(JSON::Schema::ValidationError)
        end

        it 'rejects arrays with invalid types' do
          invalid_post = valid_post.merge(multi_props: [{text: 2}])
          result = publisher.validate_object_to_publish('Post', invalid_post)
          expect(result).to be false
        end
      end
    end

    context "to consume" do
      let(:valid_post) { {title: 'My title'} }

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

      it "accepts an object with non-required properties" do
        expect(
          consumer.validate_object_to_consume!('Publisher::Post', valid_post.merge(abstract: 'im a nice extra'))
               ). to be true
      end

      it "accepts a valid object" do
        expect(
          consumer.validate_object_to_consume('Publisher::Post', valid_post)
        ).to be true
      end
      
      it "accepts objects with additional properties" do
        expect(
          consumer.validate_object_to_consume('Publisher::Post', valid_post.merge(id: '1') )
        ).to be true

      end

      it "rejects an invalid object with an exception" do
        invalid_post = { tag: 'string', title: 'My title' }
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
