RSpec::Matchers.define :match_schema do |schema|
  match do |object|
    schema.validate(object).first == true
  end

  failure_message do |object|
    "expected that\n\n#{JSON.pretty_generate(object)}\n\nwould match\n\n#{JSON.pretty_generate(schema.data)}\n\n"
  end

  failure_message_when_negated do |object|
    "expected that\n\n#{JSON.pretty_generate(object)}\n\n would not match \n\n#{JSON.pretty_generate(schema.data)}\n\n"
  end
end
