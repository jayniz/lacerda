require 'spec_helper'

describe MinimumTerm::Compare::JsonSchema do

  before(:all) do
    @schema_hash = { 
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

    @to_compare_schema_hash = {
      "$schema" => "http://json-schema.org/draft-04/schema#",
      "definitions" => {
        "post" => {
          "type" => "object",
          "properties" => { "id" => { "type" => "number" }, "name" => { "type" => "string" } },
          "required" => [ "id", "name" ]
        }
      }
    }

    @schema = MinimumTerm::Compare::JsonSchema.new(@schema_hash)
  end

    describe "#contains?" do
      
      context "Json Schema containing other Json Schema" do  
        context "contains all the definitions" do
          it "doesn't detect a difference" do
            expect(@schema.contains?(@to_compare_schema_hash)).to be_truthy
          end
        end

        context "containing all the definitions and the properties" do
          it "doesn't detect a difference" do
            @to_compare_schema_hash['definitions']['post']['properties'].delete('name')

            expect(@schema.contains?(@to_compare_schema_hash)).to be_truthy
          end
        end

        context "containing all the required attributes" do
          it "doesn't detect a difference" do
            @to_compare_schema_hash['definitions']['post']['required'].delete('name')

            expect(@schema.contains?(@to_compare_schema_hash)).to be_truthy
          end
        end
      end

      context "Json Schema NOT containing other Json Schema" do
        context "NOT contains all the definitions" do
          it "detects the difference" do
            @to_compare_schema_hash['definitions']['user'] = {}

            expect(@schema.contains?(@to_compare_schema_hash)).to be_falsey
          end
        end

        context "containing all the definitions but NOT the properties" do
          it "detects the difference" do
            expect(@schema.contains?(@to_compare_schema_hash)).to be_falsey
          end
        end

        context "NOT containing all the required attributes" do
          it "detects the difference" do
            expect(@schema.contains?(@to_compare_schema_hash)).to be_falsey
          end
        end
      end
    end
end