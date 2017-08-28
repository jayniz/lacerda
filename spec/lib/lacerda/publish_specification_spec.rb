require 'spec_helper'

RSpec.describe Lacerda::PublishSpecification do
  let(:publish_schema_file) do
    folder = '../../../support/contracts/specification'
    File.expand_path("#{folder}/publish.schema.json", __FILE__)
  end

  let(:publish_schema){ JSON.parse(open(publish_schema_file).read) }

  before(:all) do
    FileUtils.rm(publish_schema_file) rescue nil
    folder = '../../../support/contracts/specification'
    publish_mson_file = File.expand_path("#{folder}/publish.mson", __FILE__)
    Lacerda::Conversion.mson_to_json_schema!(filename: publish_mson_file)
  end

  describe '#object' do
    let(:specification) do
      service = double('Lacerda::Service')
      expect(service).to receive(:name).and_return('foo').at_most(3).times
      described_class.new(service, publish_schema)
    end
    it 'returns a PublishedObject for unscoped objects' do
      object = specification.object('Baz', scoped: false)
      expect(object).to be_a Lacerda::PublishedObject
    end

    it 'returns a PublishedObject for scoped objects' do
      object = specification.object('Foo::Bar', scoped: true)
      expect(object).to be_a Lacerda::PublishedObject
    end

    it 'scopes unscoped objects when scoped: true' do
      object = specification.object('Bar', scoped: true)
      expect(object).to be_a Lacerda::PublishedObject
    end
  end
end
