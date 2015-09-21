#!/usr/bin/env ruby
require 'bundler'
Bundler.require

$:.unshift File.join(File.dirname(__FILE__), "lib")
require "minimum_term"

# publish = RedSnow.parse(open('../contracts/author/publish.json').read)
# consume = RedSnow.parse(open('../contracts/edward/consume.json').read)
# tmp = RedSnow.parse(open('../explore/blueprint.apib').read)
# 
# minimal = RedSnow.parse("
# # Author
# # Data Structures
# ## My Object
# - name: john")

binding.pry
