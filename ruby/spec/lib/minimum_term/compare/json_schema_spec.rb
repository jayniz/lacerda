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
          "required" => [ "id", "name" ]
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

  let(:schema) { MinimumTerm::Compare::JsonSchema.new(@schema_hash) }

  describe ".contains?" do

    context "Json Schema 'a' containing Json Schema 'b'" do  
      
      it "doesn't detect a difference" do
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a['definitions'], schema_a['definitions'])).to be_truthy
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a['definitions'], schema_c['definitions'])).to be_truthy
      end
    end

    context "Json Schema 'a' NOT containing other Json Schema 'b'" do

      it "detects the difference" do
        expect(MinimumTerm::Compare::JsonSchema.contains?(schema_a['definitions'], schema_b['definitions'])).to be_falsey
      end
    end
  end
end