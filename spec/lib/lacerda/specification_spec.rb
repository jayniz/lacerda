require 'spec_helper'

describe Lacerda::Specification do
  let(:service){ $test_infrastructure.services[:consumer] }

  it "allows initialization with a loaded schema" do
    schema = {"definitions" => [] }
    expect{
      specification = Lacerda::Specification.new(service, schema)
      expect(specification.schema).to eq schema
    }.to_not raise_error
  end
end
