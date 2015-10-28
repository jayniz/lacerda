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
    end

    context 'Json Schema a NOT containing other Json Schema b because of' do

      it 'a missing definition' do
        schema_b['definitions']['user'] = {}

        expect(comparator.contains?(schema_b)).to be false
        expect(comparator.errors.first[:error]).to be :ERR_MISSING_DEFINITION
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
end
