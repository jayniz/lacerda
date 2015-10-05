require 'json-schema'

schema_data = <<SCHEMA
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "definitions": {
    "other": {
      "type": "object",
      "properties": { "id": { "type": "number" } },
      "required": [ "id" ]
    }
  },
  "type": "object",
  "properties": {
    "reference": { "$ref": "#/definitions/other" }
  }
}
SCHEMA

data = <<DATA
  {
    "referenced": {"id": "Oh no, a string, this should fail" }
  }
DATA

JSON::Validator.validate!(JSON.parse(schema_data), JSON.parse(data), validate_schema: true)
puts "Hi there, this didn't fail"
