require 'spec_helper'


describe MinimumTerm::Conversion do
  context "doing basic mson->json schema conversion" do
    let(:schema_file) { File.expand_path("../../../fixtures/test.schema.json", __FILE__)}
    let(:schema){ JsonSchema.parse!(JSON.parse(open(schema_file).read)) }

    before(:all) do
      FileUtils.rm(schema_file) rescue nil
      mson_file = File.expand_path("../../../fixtures/test.mson", __FILE__)
      MinimumTerm::Conversion.mson_to_json_schema(mson_file)
    end

    after(:all) do
      FileUtils.rm(schema_file) rescue nil
    end

    it "created a schema file" do
      expect(File.exist?(schema_file)).to be true
    end

    it "created a parseable json schema" do
      expect{
        schema
      }.to_not raise_error
    end

    it "registered both types" do
      expect(schema.definitions.keys.sort).to eq ["post", "tag"]
    end

    it "found the tag description" do
      expect(schema.definitions['tag'].description).to eq "Guten Tag"
    end

    context "validating objects that" do
      let(:tag){ schema.definitions['tag'] }

      it "are valid" do
        expect(tag.validate('id' => 1).last).to eq []
      end

      it "have a wrong type" do
        expect(tag.validate('id' => '1').first).to eq false
      end

      it "miss a required type" do
        expect(tag.validate('name' => 'test').first).to eq false
      end
    end
  end
end
