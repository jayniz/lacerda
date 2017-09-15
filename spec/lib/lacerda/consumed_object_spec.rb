require 'spec_helper'

RSpec.describe Lacerda::ConsumedObject do
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:o) { consumer.consumed_objects.first }

  it "knows its defining service" do
    expect(o.consumer).to eq consumer
  end

  it "knows the service its referring to" do
    expect(o.publisher).to eq publisher
  end
end
