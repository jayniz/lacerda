require 'spec_helper'

describe Lacerda::Contract do
  let(:service){ $test_infrastructure.services[:consumer] }

  it "allows initialization with a loaded schema" do
    schema = {"definitions" => [] }
    expect{
      contract = Lacerda::Contract.new(service, schema)
      expect(contract.schema).to eq schema
    }.to_not raise_error
  end
end
