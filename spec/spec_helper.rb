$:.unshift File.expand_path("../lib", __FILE__)
require 'rubygems'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start{ add_filter 'spec/'}

Dir[File.join(File.dirname(__FILE__), "/support/**/*.rb")].each{ |f| require f }

require 'bundler'
Bundler.require
require 'lacerda'

RSpec.configure do |config|

  # Convert/load test infrastructure, services and contracts
  config.before(:suite) do
    $contracts_dir = File.join(File.dirname(__FILE__), "support", "contracts")
    path = File.join($contracts_dir, "service_test")
    $test_infrastructure = Lacerda::Infrastructure.new(data_dir: path)
    $test_infrastructure.convert_all!(true)
  end

  # Disabled this until I figured out why it stopped the coverage
  # report from being written
  #
  # # Enforce 100% test coverage unless we're running in guard
  # config.after(:suite) do
  #   example_group = RSpec.describe('Code coverage')
  #   example = example_group.example('must be 100%'){
  #     expect( SimpleCov.result.covered_percent ).to eq 100
  #   }
  #   example_group.run

  #   passed = example.execution_result.status == :passed
  #   if passed or ENV['IGNORE_LOW_COVERAGE']
  #     RSpec.configuration.reporter.example_passed example
  #   else
  #     RSpec.configuration.reporter.example_failed example
  #   end
  # end

  config.order = :random
end
