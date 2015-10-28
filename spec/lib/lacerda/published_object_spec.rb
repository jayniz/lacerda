require 'spec_helper'

describe Lacerda::PublishedObject do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:o) { publisher.published_objects.first }

  it "knows its defining service" do
    expect(o.consumer).to eq publisher
  end

  it "knows the service its referring to" do
    expect(o.publisher).to eq publisher
  end
end
