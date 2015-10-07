require 'spec_helper'


describe MinimumTerm::Conversion do
  context "doing basic mson->json schema conversion" do
    let(:schema_file) { File.expand_path("../../../support/contracts/some_app/publish.schema.json", __FILE__)}
    let(:schema){ JSON.parse(open(schema_file).read) }

    before(:all) do
      FileUtils.rm(schema_file) rescue nil
      mson_file = File.expand_path("../../../support/contracts/some_app/publish.mson", __FILE__)
      MinimumTerm::Conversion.mson_to_json_schema(mson_file)
    end

    after(:all) do
      # TODO FileUtils.rm(schema_file) rescue nil
    end

    it "allows empty files" do
      empty_mson_file = File.expand_path("../../../support/contracts/some_app/empty.mson", __FILE__)
      expect{
        MinimumTerm::Conversion.mson_to_json_schema(empty_mson_file)
      }.to_not raise_error
    end

    it "created a schema file" do
      expect(File.exist?(schema_file)).to be true
    end

    it "created a parseable json schema" do
      expect{
        JSON::Validator.validate(schema, {}, :validate_schema => true)
      }.to_not raise_error
    end

    it "registered both types" do
      expect(schema['definitions'].keys.sort).to eq ["some_app:post", "some_app:tag"]
    end

    it "found the tag description" do
      expect(schema['definitions']['some_app:tag']['description']).to eq "Very basic tag implementation with a url slug and multiple variations of the tag name."
    end

    context "validating objects that" do
      let(:valid_tag){ {'id' => 1} }

      it "are valid" do
        expect(valid_tag).to match_schema(schema, :tag)
      end

      it "have a wrong type" do
        expect('id' => '1').to_not match_schema(schema, :tag)
      end

      it "have a wrong type array item" do
        expect('id' => 1, 'variations' => [1]).to_not match_schema(schema, :tag)
      end

      it "miss a required type" do
        expect('slug' => 'test').to_not match_schema(schema, :tag)
      end

      context "have properties with custom types that is" do
        let(:valid_post){ {'id' => 1, 'title' => 'Servus', 'author_id' => 22} }
        let(:invalid_tag){ {'id' => 1, 'variations' => [1]} }

        it "nonexistant" do
          expect(valid_post).to match_schema(schema, :post)
        end

        it "valid" do
          object = valid_post.merge('primary_tag' => valid_tag)
          expect(object).to match_schema(schema, :post)
        end

        it "invalid" do
          object = valid_post.merge('primary_tag' => invalid_tag)
          expect(object).to_not match_schema(schema, :post)
        end
      end
    end
  end
end
