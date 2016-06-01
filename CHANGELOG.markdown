# 0.14.1
- make rspec reporter be a little more ignorant

# 0.14.0
- FIX: a required array property may contain an empty array
- don't expose local definitions as published objects

# 0.13.1
- don't choke on schemas without local definitions

# 0.13.1
- don't set type and oneOf in json schema, just oneOf
- update blumquist from ~> 0.3 to ~> 0.4

# 0.13.0
- enhance some error messages (invalid object types)
- make non required properties nullable https://github.com/moviepilot/lacerda/pull/21

# 0.12.5
- fix https://github.com/moviepilot/zeta/issues/18 (infinite loops
  for some cases where json pointers are used)

# 0.12.4
- fix https://github.com/moviepilot/lacerda/issues/17

# 0.12.3
- fix missing property descriptions in json schema conversion

# 0.12.2
- don't crash when a specification has a missing definition, but report the error
- make stdout reporter a little more informative and pretty

# 0.12.1 (12-Nov-15)
- allow empty publish specifications

# 0.12.0 (11-Nov-15)
- add Lacerda::Service#publishes?(object_name)
- add Lacerda::Service#consumes?(object_name)
- add Lacerda::Service#consumes_from?(service_name, object_name)
- add Lacerda::Service#consume_object_from(service_name, object_name)
- load Lacerda::VERSION
- add missing json-schema require
- fix a typo in the ERR_MISSING_DEFINITION error message
- update blumquist
- allow top level types without a publishing service prefix in consume specifications

# 0.11.0 (04-Nov-15)
- rename ConsumeContract and PublishContract to ConsumeSpecification and PublishSpecification
- omit redundant service name in model names of publish contracts

# 0.10.2 (04-Nov-15)
- report all missing definitions instead of just the first (fixes #8)

# 0.10.1 (03-Nov-15)
- Use `# Data Structures` with an s

# 0.10.0 (03-Nov-15)
- Make `# Data Structure` header for specifications optional

# 0.9.0 (03-Nov-15)
- add RSpec reporter

# 0.8.0 (30-Oct-15)
- support for custom reporters
- extract current output into and stdout reporter

# 0.7.0 (30-Oct-15)
- change ServiceName:ObjectName to ServiceName::ObjectName

# 0.6.2 (30-Oct-15)
- fix some forgotten ruby 2.0 syntax
- my name is Jannis and I am a compulsive obsessive rake releaser

# 0.6.1 (30-Oct-15)
- fix some forgotten ruby 2.0 syntax

# 0.6.0 (30-Oct-15)
- bump Blumquist version to the one that auto validates
- be ruby <2 compatible

# 0.5.0 (29-Oct-15)
- add `consume_object` method that returns Blumquist wrapped data

# 0.4.0 (29-Oct-15)
- validation helpers for published and consumed objects
- enhance some error messages

# 0.3.3 (28-Oct-15)
- add error messages

# 0.3.2 (28-Oct-15)
- fix wrongly named rake task
- fix case where an infrastructure with a missing publishing service was reported as valid

# 0.3.0 (28-Oct-15)
- rename to Lacerda

# 0.2.4 (23-Oct-15)
- fix deep clone bug for schema scoping

# 0.2.3 (22-Oct-15)
- ignore consumed objects from other publishers when validating

# 0.2.2
- allow missing property type in MSON and default to 'object'
