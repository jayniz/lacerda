require 'pry'
require 'spec_helper'
include Lacerda::Compare

describe JsonSchema do

  let(:schema_a) {
    {
      '$schema' => 'http://json-schema.org/draft-04/schema#',
      'definitions' => {
        'tag' => {
          'type' => 'object',
          'properties' => { 'id' => { 'type' => 'number', 'description' => 'Foobar' } },
          'required' => [ 'id' ],
        },
        'post' => {
          'type' => 'object',
          'properties' => {
            'id' => { 'type' => 'number', 'description' => 'The unique identifier for a post' },
            'title' => { 'type' => 'string', 'description' => 'Title of the product' },
            'author' => { 'type' => 'number', 'description' => 'External user id of author' },
            'tags' => { 'type' => 'array', 'items' => [ { 'type' => 'string' } ] }
          },
          'required' => [ 'id', 'title' ]
        }
      },
      'properties' => {
        'post' => { '$ref' => '#/definitions/post' },
        'tag'  => { '$ref' => '#/definitions/tag' }
      }
    }
  }

  let(:schema_b) {
    {
      '$schema' => 'http://json-schema.org/draft-04/schema#',
      'definitions' => {
        'post' => {
          'type' => 'object',
          'properties' => {
            'id' => { 'type' => 'number' },
            'tags' => { 'type' => 'array', 'items' => [ { 'type' => 'string' } ] }
          },
          'required' => [ 'id', 'title' ]
        }
      },
      'properties' => {
        'post' => { '$ref' => '#/definitions/post' }
      }
    }
  }

  let(:schema_broken) {
    {
      '$schema' => 'http://json-schema.org/draft-04/schema#',
      'definitions' => {
        'post' => {
          'type' => 'object',
          'BROKEN' => {
            'id' => { 'type' => 'number' },
            'tags' => { 'type' => 'array', 'items' => [ { 'type' => 'string' } ] }
          },
          'required' => [ 'id', 'title' ]
        }
      },
      'properties' => {
        'post' => { '$ref' => '#/definitions/post' }
      }
    }
  }

  context "unit tests" do
    let(:schema){ {'definitions' => { "foo" => :bar }} }
    let(:js){ JsonSchema.new(schema) }

    describe "#data_for_pointer" do
      it "inline object" do
        inline = {'type' => 'object', properties: :foo }
        expect(js.send(:data_for_pointer, inline, schema)).to eq inline
      end

      it "pointer via $ref" do 
        ref = { "$ref" => "#/definitions/foo" }
        expect(js.send(:data_for_pointer, ref, schema)).to eq :bar
      end

      it "string pointer" do
        string = "foo"
        expect(js.send(:data_for_pointer, string, schema)).to eq :bar
      end
    end
  end

  context "integration tests" do
    describe '#contains?' do
      let(:comparator){ JsonSchema.new(schema_a) }

      let(:tag_as_pointer){ { '$ref' => '#/definitions/tag' } }
      let(:tag_as_inline_object) {
        {
          'type' => 'object',
          'properties' => {
            'id' => {'type' => 'number'}
          }
        }
      }

      context 'Json Schema with broken object (without "properties" or "oneOf")' do
        # this is a very unlikely case where the schema for some reason neither has
        # properties nor oneOf for type object
        it 'fails to load the schema' do
          schema = JsonSchema.new(schema_broken)
          expect(schema.contains?(schema_broken)).to be false
          expect(schema.errors[0][:error]).to be :ERR_NOT_SUPPORTED
        end
      end

      context 'Json Schema a containing Json Schema b' do

        it 'when they are equal' do
          expect(comparator.contains?(schema_a)).to be true
        end

        it 'when one is contained in the other' do
          expect(comparator.contains?(schema_b)).to be true
        end

        it 'when the child schema describes a child object as a ref' do
          schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
          schema_b['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
          schema_b['definitions']['tag'] = tag_as_inline_object
          expect(comparator.contains?(schema_b)).to be true
        end

        it 'when the child schema describes a child object instead of using a reference' do
          schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
          schema_b['definitions']['post']['properties']['primary_tag'] = tag_as_inline_object
          expect(comparator.contains?(schema_b)).to be true
        end

        it 'when the child schema describes a child object via a pointer' do
          schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
          schema_a['definitions']['primary_tag'] = tag_as_inline_object
          expect(comparator.contains?(schema_b)).to be true
        end

        it 'when the child schema describes a child object via a pointer but the containing object inline' do
          schema_a['definitions'].delete('tag')
          schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_inline_object

          schema_b['definitions']['tag'] = tag_as_inline_object
          schema_b['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
          expect(comparator.contains?(schema_b)).to be_falsy
        end

        describe "with oneOfs" do
          it 'consume marks a property nullable that is not nullable in the publish' do
            publish = <<-JSON
              {
                "$schema": "http://json-schema.org/draft-04/schema#",
                "title": "publisher",
                "definitions": {
                  "testObject": {
                    "type": "object",
                    "properties": {
                      "id": {
                        "type": [
                          "number"
                        ],
                        "description": ""
                      }
                    },
                    "required": [ "id" ]
                  }
                },
                "type": "object",
                "properties": {
                  "testObject": {
                    "$ref": "#/definitions/testObject"
                  }
                }
              }
            JSON

            consume = <<-JSON
              {
                "$schema": "http://json-schema.org/draft-04/schema#",
                "title": "publisher",
                "definitions": {
                  "testObject": {
                    "type": "object",
                    "oneOf": [
                      { "type": "null" },
                      {
                        "type": "object",
                        "required": [ "id" ],
                        "properties": {
                          "id": {
                            "type": [
                              "number"
                            ],
                            "description": ""
                          }
                        }
                      }
                    ]
                  }
                },
                "type": "object",
                "properties": {
                  "testObject": {
                    "$ref": "#/definitions/testObject"
                  }
                }
              }
            JSON

            comparator = JsonSchema.new(JSON.parse(publish))
            expect(comparator.contains?(JSON.parse(consume))).to be true
          end

          it 'consume marks a property nullable that is not nullable in the publish' do
            consume = <<-JSON
              {
                "$schema": "http://json-schema.org/draft-04/schema#",
                "title": "publisher",
                "definitions": {
                  "testObject": {
                    "type": "object",
                    "properties": {
                      "id": {
                        "type": [
                          "number"
                        ],
                        "description": ""
                      }
                    },
                    "required": [ "id" ]
                  }
                },
                "type": "object",
                "properties": {
                  "testObject": {
                    "$ref": "#/definitions/testObject"
                  }
                }
              }
            JSON

            publish = <<-JSON
              {
                "$schema": "http://json-schema.org/draft-04/schema#",
                "title": "publisher",
                "definitions": {
                  "testObject": {
                    "type": "object",
                    "oneOf": [
                      { "type": "null" },
                      {
                        "type": "object",
                        "required": [ "id" ],
                        "properties": {
                          "id": {
                            "type": [
                              "number"
                            ],
                            "description": ""
                          }
                        }
                      }
                    ]
                  }
                },
                "type": "object",
                "properties": {
                  "testObject": {
                    "$ref": "#/definitions/testObject"
                  }
                }
              }
            JSON

            comparator = JsonSchema.new(JSON.parse(publish))
            expect(comparator.contains?(JSON.parse(consume))).to be false
          end
        end
      end

      context 'Json Schema a NOT containing other Json Schema b because of' do

        it 'two missing definitions' do
          schema_a['properties'].delete 'post'
          schema_b['properties']['non_existant'] = { type: 'object', properties: {}}

          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors[0][:error]).to be :ERR_MISSING_DEFINITION
          expect(comparator.errors[1][:error]).to be :ERR_MISSING_DEFINITION
        end

        it 'different types for the object' do
          schema_b['definitions']['post']['type'] = 'string'

          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.first[:error]).to be :ERR_TYPE_MISMATCH
        end

        it 'a missing property' do
          schema_b['definitions']['post']['properties']['name'] = {}

          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.first[:error]).to be :ERR_MISSING_PROPERTY
        end

        it 'a different type of a property' do
          schema_b['definitions']['post']['properties']['id']['type'] = 'string'

          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.first[:error]).to be :ERR_TYPE_MISMATCH
        end

        it 'a different type of reference' do
          schema_b['definitions']['post']['properties']['primary_tag'] = { '$ref' => '#/definitions/something_else' }
          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.first[:error]).to be :ERR_MISSING_PROPERTY
        end

        it 'a missing required property' do
          schema_b['definitions']['post']['required'] << 'name'

          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.first[:error]).to be :ERR_MISSING_REQUIRED
        end

        it 'a missing pointer' do
          schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
          schema_b['definitions']['post']['properties']['primary_tag'] = tag_as_inline_object
          schema_b['definitions']['tag'] = tag_as_inline_object
          schema_a['definitions'].delete('tag')
          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.first[:error]).to be :ERR_MISSING_POINTER
        end

        it 'a different type for the items of a property of type array' do
          schema_b['definitions']['post']['properties']['tags']['items'].first['type'] = 'number'

          expect(comparator.contains?(schema_b)).to be false
          expect(comparator.errors.length).to be 2
          expect(comparator.errors.map{|d| d[:error] }.sort).to eq [:ERR_ARRAY_ITEM_MISMATCH, :ERR_TYPE_MISMATCH]
        end
      end
    end

    context 'oneOfs' do

      context 'in just consume' do
        let(:including){ JSON.parse <<-JSON
        {
          "$schema": "http://json-schema.org/draft-04/schema#",
          "title": "publisher",
          "definitions": {
            "testObject": {
              "type": "object",
              "properties": {"id": {"type": "number"}, "name": {"type": "string"}},
              "required": ["name"]
            }
          },
          "type": "object",
          "properties": {
            "oneOfOneOfTest": {
              "$ref": "#/definitions/testObject"
            }
          }
        }
        JSON
        }
        let(:included){ JSON.parse <<-JSON
        {
          "$schema": "http://json-schema.org/draft-04/schema#",
          "title": "consumer",
          "definitions": {
            "testObject": {
              "oneOf": [{"type": "object", "properties": {"true": {"type": "boolean"}}} ]
            }
          },
          "type": "object",
          "properties": {
            "oneOfOneOfTest": {
              "$ref": "#/definitions/testObject"
            }
          }
        }
        JSON
        }

        it 'no compatible oneOf in the consume schema is found' do
          comparator = JsonSchema.new(including)
          result = comparator.contains?(included)
          expect(result).to be_falsy
        end
      end

      context 'in both publish and consume' do
        let(:including){ JSON.parse <<-JSON
        {
          "$schema": "http://json-schema.org/draft-04/schema#",
          "title": "publisher",
          "definitions": {
            "testObject": {
              "oneOf": [{"type": "object", "properties": {"id": {"type": "number"}, "name": {"type": "string"}}, "required": ["name"]}, {"type": "null"} ]
            }
          },
          "type": "object",
          "properties": {
            "oneOfOneOfTest": {
              "$ref": "#/definitions/testObject"
            }
          }
        }
                         JSON
        }
        let(:included){ JSON.parse <<-JSON
        {
          "$schema": "http://json-schema.org/draft-04/schema#",
          "title": "consumer",
          "definitions": {
            "testObject": {
              "oneOf": [{"type": "object", "properties": {"id": {"type": "number"}}}, {"type": "null"} ]
            }
          },
          "type": "object",
          "properties": {
            "oneOfOneOfTest": {
              "$ref": "#/definitions/testObject"
            }
          }
        }
                        JSON
        }
        it 'one schema containing the other' do
          comparator = JsonSchema.new(including)
          result = comparator.contains?(included)
          expect(result).to be_truthy
        end

        it 'one schema not containing the other' do
          comparator = JsonSchema.new(included)
          $debug = ENV['DEBUG'].present?
          result = comparator.contains?(including)
          expect(result).to be_falsy
        end
      end
    end
  end
end
