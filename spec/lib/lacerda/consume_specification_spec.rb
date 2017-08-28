require 'spec_helper'

RSpec.describe Lacerda::ConsumeSpecification do
  let(:consume_schema_file) do
    folder = '../../../support/contracts/specification'
    File.expand_path("#{folder}/consume.schema.json", __FILE__)
  end

  let(:consume_schema){ JSON.parse(open(consume_schema_file).read) }

  before(:all) do
    FileUtils.rm(consume_schema_file) rescue nil
    folder = '../../../support/contracts/specification'
    consume_mson_file = File.expand_path("#{folder}/consume.mson", __FILE__)
    Lacerda::Conversion.mson_to_json_schema!(filename: consume_mson_file)
  end

  describe '#object' do
    let(:specification) do
      service = double('Lacerda::Service')
      expect(service).to receive(:name).and_return('foo').at_most(3).times
      described_class.new(service, consume_schema)
    end
    it 'returns a ConsumeObject for unscoped objects' do
      object = specification.object('Baz')
      expect(object).to be_a Lacerda::ConsumedObject
    end

    it 'returns a ConsumeObject for scoped objects' do
      object = specification.object('Foo::Bar')
      expect(object).to be_a Lacerda::ConsumedObject
    end
  end
end
