require 'lacerda/conversion'
require 'lacerda/publish_contract'
require 'lacerda/consume_contract'
require 'lacerda/service'
require 'lacerda/infrastructure'
require 'lacerda/compare/json_schema'
require 'lacerda/reporter'
require 'lacerda/reporters/stdout'

module Lacerda
  SCOPE_SEPARATOR = '::'

  def self.validate_reporter(reporter)
    return reporter unless reporter
    return reporter if reporter.class <= Lacerda::Reporter
    raise "reporter must inherit from Lacerda::Reporter, but #{reporter.class.name} doesn't"
  end

  # An underscore that doesn't turn :: into /
  def self.underscore(string)
    string.gsub(/#{SCOPE_SEPARATOR}/, ':')
          .underscore
          .gsub(/:/, SCOPE_SEPARATOR)
  end
end
