require 'spec_helper'

describe MinimumTerm::Compare::JsonSchema do

  let(:schema_a) {
    {
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "definitions" => {
        "tag" => {
          "type" => "object",
          "properties" => { "id" => { "type" => "number", "description" => "Foobar" } },
          "required" => [ "id" ],
        },
        "post" => {
          "type" => "object",
          "properties" => {
            "id" => { "type" => "number", "description" => "The unique identifier for a post" },
            "title" => { "type" => "string", "description" => "Title of the product" },
            "author" => { "type" => "number", "description" => "External user id of author" },
            "tags" => { "type" => "array","items" => [ { "$ref" => "#/definitions/tag" } ] }
          },
          "required" => [ "id", "title" ]
        }
      }
    }
  }

  let(:schema_b) {
    {
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "definitions" => {
        "post" => {
          "type" => "object",
          "properties" => { "id" => { "type" => "number" }, "name" => { "type" => "string" } },
          "required" => [ "id", "title" ]
        }
      }
    }
  }

  let(:schema_c) { 
    {
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "definitions" => {
        "post" => {
          "type" => "object",
          "properties" => { "id" => { "type" => "number" } },
          "required" => [ "id" ]
        }
      }
    }
  }

  describe "#contains?" do

    context "Json Schema 'a' containing Json Schema 'b'" do

      it "doesn't detect a difference" do
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_a)).to be_truthy
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_c)).to be_truthy
      end

    context "Json Schema 'a' NOT containing other Json Schema 'b' because of" do

      it "a missing definition" do
        schema_c['definitions']['user'] = {}
        
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_c)).to be_falsey
      end

      it "different types for the object" do
        schema_c['definitions']['post']['type'] = 'string'
        
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_c)).to be_falsey
      end

      it "a missing property" do
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_b)).to be_falsey
      end

      it "a different type of a property" do
        schema_c['definitions']['post']['properties']['id']['type'] = 'string'

        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_c)).to be_falsey
      end

      it "a missing required property" do
        schema_c['definitions']['post']['required'] << 'name'

        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a, schema_c)).to be_falsey
      end
    end
  end
end