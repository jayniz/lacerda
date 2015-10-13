require 'spec_helper'

describe MinimumTerm::Infrastructure do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:consumer_invalid_property){ $test_infrastructure.services[:invalid_property] }
  let(:consumer_missing_required){ $test_infrastructure.services[:missing_required] }

  it "counts publishers correctly" do
    expect($test_infrastructure.publishers).to eq [publisher]
  end

  it "lists consumers correctly" do
    expect($test_infrastructure.consumers).to eq [consumer, consumer_invalid_property, consumer_missing_required]
  end

  it "checks to see if all contracts are fulfilled" do
    expect($test_infrastructure.contracts_fulfilled?).to be false
  end
end
