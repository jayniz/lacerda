require 'spec_helper'
include MinimumTerm::Compare

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
      }
    }
  }

  describe '#contains?' do

    let(:tag_as_pointer){ { '$ref' => '#/definitions/tag' } }
    let(:tag_as_inline_object) {
      {
        'type' => 'object',
        'properties' => {
          'id' => {'type' => 'number'}
        }
      }
    }

    context 'Json Schema a containing Json Schema b' do

      it 'when they are equal' do
        expect(JsonSchema.new(schema_a).contains?(schema_a)).to be_truthy
      end

      it 'when one is contained in the other' do
        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_truthy
      end

      it 'when the child schema describes a child object as a ref' do
        schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
        schema_b['definitions']['post']['properties']['primary_tag'] = { '$ref' => '#/definitions/tag' }
        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_truthy
      end

      it 'when the child schema describes a child object instead of using a reference' do
        schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
        schema_b['definitions']['post']['properties']['primary_tag'] = tag_as_inline_object
        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_truthy
      end

      it 'when the child schema describes a child object via a pointer' do
        schema_a['definitions']['post']['properties']['primary_tag'] = tag_as_pointer
        schema_a['definitions']['primary_tag'] = tag_as_inline_object
        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_truthy
      end
    end

    context 'Json Schema a NOT containing other Json Schema b because of' do

      it 'a missing definition' do
        schema_b['definitions']['user'] = {}

        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_falsey
      end

      it 'different types for the object' do
        schema_b['definitions']['post']['type'] = 'string'

        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_falsey
      end

      it 'a missing property' do
        schema_b['definitions']['post']['properties']['name'] = {}

        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_falsey
      end

      it 'a different type of a property' do
        schema_b['definitions']['post']['properties']['id']['type'] = 'string'

        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_falsey
      end

      it 'a different type of reference' do
        schema_b['definitions']['post']['properties']['primary_tag'] = { '$ref' => '#/definitions/something_else' }
        expect(JsonSchema.new(schema_a).contains?(schema_b)).to_not be_truthy
      end

      it 'a missing required property' do
        schema_b['definitions']['post']['required'] << 'name'

        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_falsey
      end

      it 'a different type for the items of a property of type array' do
        schema_b['definitions']['post']['properties']['tags']['items'].first['type'] = 'number'

        expect(JsonSchema.new(schema_a).contains?(schema_b)).to be_falsey
      end
    end
  end
end
