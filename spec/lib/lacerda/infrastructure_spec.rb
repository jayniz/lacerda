require 'spec_helper'

describe Lacerda::Infrastructure do
  let(:publisher){ $test_infrastructure.services[:publisher] }
  let(:consumer){ $test_infrastructure.services[:consumer] }
  let(:consumer_invalid_property){ $test_infrastructure.services[:invalid_property] }
  let(:consumer_missing_required){ $test_infrastructure.services[:missing_required] }

  it "allows to refresh the data" do
    expect{$test_infrastructure.reload}.to_not raise_error
  end

  it "counts publishers correctly" do
    expect($test_infrastructure.publishers).to eq [publisher]
  end

  it "lists consumers correctly" do
    expect($test_infrastructure.consumers).to eq [consumer, consumer_invalid_property, consumer_missing_required]
  end

  it "checks to see if all contracts are fulfilled" do
    expect($test_infrastructure.contracts_fulfilled?).to be false
  end

  context "fail when there's consumed objects that nobody publishes" do
    before(:all) do
      path = File.join($contracts_dir, "only_consumer")
      @i = Lacerda::Infrastructure.new(data_dir: path)
      @i.convert_all!
      @i.contracts_fulfilled?(Lacerda::Reporter.new)
    end

    it "contracts are not fulfilled" do
      expect(@i.contracts_fulfilled?).to be false
    end

    it "has an error message" do
      expect(@i.errors.length).to be 1
    end

    it "refuses to work with a dubious reporter" do
      class RaolDuke; end
      expect{
        @i.contracts_fulfilled?(RaolDuke.new)
      }.to raise_error("reporter must inherit from Lacerda::Reporter, but RaolDuke doesn't")
    end
  end
end
