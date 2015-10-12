require 'spec_helper'

# We're relying on the test services defined in
# spec/support/contracts
describe MinimumTerm::Service do
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:publisher){ $test_infrastructure.services[:publisher] }

  it "publisher doesn't depend on anybody" do
    expect(publisher.dependant_on.length).to be 0
  end

  it "consumer depends on publisher" do
    expect(consumer.dependant_on.first).to be publisher
  end

  it "publisher knows that consumer depends on it" do
    expect(publisher.dependants).to eq [consumer]
  end

  it "publisher publishes one object" do
    expect(publisher.published_objects.length).to eq 1
  end

end
