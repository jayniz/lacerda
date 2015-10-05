require 'json'
require 'json_schema'


schema_data = <<SCHEMA
{
  "$schema": "http://json-schema.org/schema#",
  "definitions": {
    "other": {
      "type": "object",
      "properties": { "id": { "type": "number" } },
      "required": [ "id" ]
    }
  },
  "type": "object",
  "properties": {
    "myref": { "$ref": "#/definitions/other" }
  }
}
SCHEMA

data = <<DATA
  {
    "myref": {"id": "Oh god, a string, this should fail" }
  }
DATA

JsonSchema.parse!(JSON.parse(schema_data)).validate!(JSON.parse(data))
puts "Hi there, this didn't fail"
