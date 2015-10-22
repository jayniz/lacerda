require 'spec_helper'


describe MinimumTerm::Conversion do
  context "doing basic mson->json schema conversion" do
    let(:publish_schema_file) { File.expand_path("../../../support/contracts/json_schema_test/app/publish.schema.json", __FILE__)}
    let(:publish_schema){ JSON.parse(open(publish_schema_file).read) }
    let(:consume_schema_file) { File.expand_path("../../../support/contracts/json_schema_test/app/consume.schema.json", __FILE__)}
    let(:consume_schema){ JSON.parse(open(consume_schema_file).read) }

    before(:all) do
      FileUtils.rm(publish_schema_file) rescue nil
      FileUtils.rm(consume_schema_file) rescue nil

      publish_mson_file = File.expand_path("../../../support/contracts/json_schema_test/app/publish.mson", __FILE__)
      consume_mson_file = File.expand_path("../../../support/contracts/json_schema_test/app/consume.mson", __FILE__)

      MinimumTerm::Conversion.mson_to_json_schema!(filename: publish_mson_file)
      MinimumTerm::Conversion.mson_to_json_schema!(filename: consume_mson_file)
    end

    after(:all) do
      FileUtils.rm(publish_schema_file) rescue nil
    end

    context "conversion without exceptions" do
      let(:f){ publish_schema_file }
      it "when it works" do
        expect(MinimumTerm::Conversion).to receive(:mson_to_json_schema!)
          .with(filename: f, keep_intermediary_files: false, verbose: false)
        expect(MinimumTerm::Conversion.mson_to_json_schema(filename: f)).to be true
      end

      it "when it bangs" do
        expect(MinimumTerm::Conversion).to receive(:mson_to_json_schema!)
          .with(filename: f, keep_intermediary_files: false, verbose: false).and_raise
        expect(MinimumTerm::Conversion.mson_to_json_schema(filename: publish_schema_file)).to be false
      end
    end

    it "doesn't allow names except for publish.mson and consume.mson" do
      invalidly_named_mson_file = File.expand_path("../../../support/contracts/json_schema_test/app/invalid_name.mson", __FILE__)
      expect{
        MinimumTerm::Conversion.mson_to_json_schema!(filename: invalidly_named_mson_file)
      }.to raise_error(MinimumTerm::Conversion::Error)
    end

    it "allows empty files" do
      empty_mson_file = File.expand_path("../../../support/contracts/empty_test/app/publish.mson", __FILE__)
      expect{
        MinimumTerm::Conversion.mson_to_json_schema!(filename: empty_mson_file)
      }.to_not raise_error
    end

    it "created a schema file" do
      expect(File.exist?(publish_schema_file)).to be true
    end

    it "created a parseable json schema" do
      expect{
        JSON::Validator.validate(publish_schema, {}, :validate_schema => true)
      }.to_not raise_error
    end

    it "registered both publish types with automatic scope from directory name" do
      expect(publish_schema['definitions'].keys.sort).to eq ["app:post", "app:tag"]
    end

    it "registered the consume type with the scope as in the schema" do
      expect(consume_schema['definitions'].keys.sort).to eq ["another_app:post"]
    end

    it "parsed child objects in the consume schema" do
      expect(consume_schema['definitions']['another_app:post']['properties']['primary_tag']['properties']['name']['type']).to eq "string"
    end

    it "found the tag description" do
      expect(publish_schema['definitions']['app:tag']['description']).to eq "Very basic tag implementation with a url slug and multiple variations of the tag name."
    end

    context "validating objects that" do
      let(:valid_tag){ {'id' => 1} }

      it "are valid" do
        expect(valid_tag).to match_schema(publish_schema, :tag)
      end

      it "have a wrong type" do
        expect('id' => '1').to_not match_schema(publish_schema, :tag)
      end

      it "have a wrong type array item" do
        expect('id' => 1, 'variations' => [1]).to_not match_schema(publish_schema, :tag)
      end

      it "miss a required type" do
        expect('slug' => 'test').to_not match_schema(publish_schema, :tag)
      end

      context "have properties with custom types that is" do
        let(:valid_post){ {'id' => 1, 'title' => 'Servus', 'author_id' => 22} }
        let(:invalid_tag){ {'id' => 1, 'variations' => [1]} }

        it "nonexistant" do
          expect(valid_post).to match_schema(publish_schema, :post)
        end

        it "valid" do
          object = valid_post.merge('primary_tag' => valid_tag)
          expect(object).to match_schema(publish_schema, :post)
        end

        it "invalid" do
          object = valid_post.merge('primary_tag' => invalid_tag)
          expect(object).to_not match_schema(publish_schema, :post)
        end
      end
    end
  end
end
