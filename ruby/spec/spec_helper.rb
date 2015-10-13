require 'rubygems'
require 'bundler'
require 'simplecov'

Bundler.require

$:.unshift File.expand_path("../lib", __FILE__)

Dir[File.join(File.dirname(__FILE__), "/support/**/*.rb")].each{ |f| require f }

SimpleCov.start
require "minimum_term"

RSpec.configure do |config|

  # Convert/load test infrastructure, services and contracts
  config.before(:suite) do
    contracts_dir = File.join(File.dirname(__FILE__), "support", "contracts")
    path = File.join(contracts_dir, "service_test")
    $test_infrastructure = MinimumTerm::Infrastructure.new(path)
    $test_infrastructure.convert_all!(true)
  end

  # Enforce 100% test coverage unless we're running in guard
  config.after(:suite) do
    unless ENV['SKIP_COVERAGE']
      example_group = RSpec.describe('Code coverage')
      example = example_group.example('must be above 100%'){
        expect( SimpleCov.result.covered_percent ).to eq 100
      }
      example_group.run

      passed = example.execution_result.status == :passed

      RSpec.configuration.reporter.example_failed example unless passed
    end
  end
  config.order = :random
end
