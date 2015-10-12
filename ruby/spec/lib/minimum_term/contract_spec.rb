require 'spec_helper'

describe MinimumTerm::Contract do
  let(:service){ $test_infrastructure.services[:consumer] }

  it "allows initialization with a loaded schema" do
    schema = {"definitions" => [] }
    expect{
      contract = MinimumTerm::Contract.new(service, schema)
      expect(contract.schema).to eq schema
    }.to_not raise_error
  end
end
