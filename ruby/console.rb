#!/usr/bin/env ruby
require 'bundler'
Bundler.require

$:.unshift File.join(File.dirname(__FILE__), "lib")
require "minimum_term"


i = MinimumTerm::Infrastructure.new

binding.pry
