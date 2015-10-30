require "lacerda/conversion"
require "lacerda/publish_contract"
require "lacerda/consume_contract"
require "lacerda/service"
require "lacerda/infrastructure"
require "lacerda/compare/json_schema"

module Lacerda
  SCOPE_SEPARATOR = '::'

  # An underscore that doesn't turn :: into /
  def self.underscore(string)
    string.gsub(/#{SCOPE_SEPARATOR}/, ':')
          .underscore
          .gsub(/:/, SCOPE_SEPARATOR)
  end
end
