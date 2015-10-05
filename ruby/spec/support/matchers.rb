RSpec::Matchers.define :match_schema do |schema, type|

  match do |object|
    schema.validate(type => object).first == true
  end

  failure_message do |object|
    "expected that\n\n#{JSON.pretty_generate(type => object)}\n\nwould match definition '#{type}' in\n\n#{JSON.pretty_generate(schema.data)}\n\n"
  end

  failure_message_when_negated do |object|
    "expected that\n\n#{JSON.pretty_generate(type => object)}\n\nwould not match definition '#{type}' in\n\n#{JSON.pretty_generate(schema.data)}\n\n"
  end
end
