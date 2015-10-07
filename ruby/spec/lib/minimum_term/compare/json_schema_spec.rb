require 'spec_helper'

describe MinimumTerm::Compare::JsonSchema do

  let(:schema_hash) { 
    {
      "$schema" => "http=://json-schema.org/draft-04/schema#",
      "definitions" => { "tag" => { "type" => "object" }, "post" => { "type" => "object" } },
      "type" => "object",
      "properties" => {
        "tag" => { "$ref" => "#/definitions/tag" },
        "post" => { "$ref" => "#/definitions/post" }
      }
    }
  }

  let(:to_compare_schema_hash) {
    {
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "definitions" => { "post" => { "type" => "object" } },
      "type" => "object",
      "properties" => { "post" => { "$ref" => "#/definitions/post" } }
    }
  }


  describe "#contains?" do
    
    context "Json Schema containing another Json Schema" do  
      context "contains all the definitions" do
        it "doesn't detect a difference" do
          schema = MinimumTerm::Compare::JsonSchema.new(schema_hash)
          expect(schema.contains?(to_compare_schema_hash)).to be_truthy
        end
      end

      context "containing all the definitions and the properties" do
        it "doesn't detect a difference" do
        end
      end
    end

    context "Json Schema NOT containing anoother Json Schema" do
      context "NOT contains all the definitions" do
        it "detects the difference" do
          to_compare_schema_hash['definitions']['user'] = {}
          schema = MinimumTerm::Compare::JsonSchema.new(schema_hash)
          expect(schema.contains?(to_compare_schema_hash)).to be_falsey
        end
      end

      context "containing all the definitions but NOT the properties" do
        it "detects the difference" do
        end
      end
    end
  end
end