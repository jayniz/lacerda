# coding: utf-8
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
SimpleCov.start{
  add_filter 'spec/'

  # Is this cheating? Have a 🍕 
  add_filter 'lib/lacerda/reporters/'
}

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

  config.order = :random
end
