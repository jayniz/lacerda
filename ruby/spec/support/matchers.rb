RSpec::Matchers.define :match_schema do |schema, type|

  match do |object|
    JSON::Validator.validate(schema, type => object)
  end

  failure_message do |object|
    "expected that\n\n#{JSON.pretty_generate(type => object)}\n\nwould match definition '#{type}' in\n\n#{JSON.pretty_generate(schema)}\n\n"
  end

  failure_message_when_negated do |object|
    "expected that\n\n#{JSON.pretty_generate(type => object)}\n\nwould not match definition '#{type}' in\n\n#{JSON.pretty_generate(schema)}\n\n"
  end
end
