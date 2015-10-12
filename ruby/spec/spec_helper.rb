require 'rubygems'
require 'bundler'
require 'simplecov'

Bundler.require

$:.unshift File.expand_path("../lib", __FILE__)

Dir[File.join(File.dirname(__FILE__), "/support/**/*.rb")].each{ |f| require f }

SimpleCov.start
require "minimum_term"
