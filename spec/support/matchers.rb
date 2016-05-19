require 'json-schema'
RSpec::Matchers.define :match_schema do |schema, type|
  scoped_type = Lacerda::Conversion::DataStructure.scope(schema['title'], type)
  error = nil

  match do |object|
    begin
      JSON::Validator.validate!(schema, scoped_type => object)
    rescue => e
      if ENV['debug']
        puts "DEBUG: type=#{type} scoped_type=#{scoped_type}"
      end
      error = e
      false
    end
  end

  failure_message do |object|
    "expected that\n\n#{JSON.pretty_generate(scoped_type => object)}\n\nwould match definition '#{scoped_type}' in\n\n#{JSON.pretty_generate(schema)} (error: #{error}\n\n"
  end

  failure_message_when_negated do |object|
    "expected that\n\n#{JSON.pretty_generate(scoped_type => object)}\n\nwould not match definition '#{scoped_type}' in\n\n#{JSON.pretty_generate(schema)}\n\n"
  end
end
