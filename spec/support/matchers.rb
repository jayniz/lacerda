require 'json-schema'
RSpec::Matchers.define :match_schema do |schema, type|
  scoped_type = Lacerda::Conversion::DataStructure.scope(schema['title'], type)

  match do |object|
    JSON::Validator.validate(schema, scoped_type => object)
  end

  failure_message do |object|
    "expected that\n\n#{JSON.pretty_generate(scoped_type => object)}\n\nwould match definition '#{scoped_type}' in\n\n#{JSON.pretty_generate(schema)}\n\n"
  end

  failure_message_when_negated do |object|
    "expected that\n\n#{JSON.pretty_generate(scoped_type => object)}\n\nwould not match definition '#{scoped_type}' in\n\n#{JSON.pretty_generate(schema)}\n\n"
  end
end
