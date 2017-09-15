require 'spec_helper'

RSpec.describe Lacerda::PublishedObject do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:o) { publisher.published_objects.first }

  it "knows its defining service" do
    expect(o.consumer).to eq publisher
  end

  it "knows the service its referring to" do
    expect(o.publisher).to eq publisher
  end

  it "transfers definitions into sub schemas" do
    d = {
      id: 1,
      title: 'title',
      body: 'text is nice',
      tag: {
        id: 1,
        name: 'name'
      },
      comments: []
    }
    object_description = publisher.publish.object(:post)
    expect{
      object_description.validate_data!(d)
    }.to_not raise_error
  end

  it "doesn't mind checking empty payloads" do
    object_description = publisher.publish.object(:post)
    expect(object_description.validate_data(nil)).to be false
  end
end
