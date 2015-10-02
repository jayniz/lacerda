require 'rubygems'
require 'bundler'
Bundler.require

$:.unshift File.expand_path("../lib", __FILE__)
require "minimum_term"

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

