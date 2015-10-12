require 'spec_helper'

# We're relying on the test services defined in
# spec/support/contracts
describe MinimumTerm::Service do
  let(:infrastructure){
    path = File.join(contracts_dir, "service_test")
    test_infrastructure = MinimumTerm::Infrastructure.new(path)
    test_infrastructure.convert_all!
    test_infrastructure
  }
  let(:consumer){ infrastructure.services[:consumer] }
  let(:publisher){ infrastructure.services[:publisher] }

  it "publisher doesn't depend on anybody" do
    expect(publisher.dependant_on.length).to be 0
  end

  it "consumer doesn't depends on publisher" do
    expect(consumer.dependant_on.first).to be publisher
  end
end
