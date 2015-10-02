#!/usr/bin/env ruby
require 'bundler'
Bundler.require

$:.unshift File.join(File.dirname(__FILE__), "lib")
require "minimum_term"

binding.pry
