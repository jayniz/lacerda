#!/usr/bin/env ruby
require 'bundler'
Bundler.require

$:.unshift File.join(File.dirname(__FILE__), "lib")
require "minimum_term"

publish = RedSnow.parse(open('../contracts/author/publish.mson').read)
consume = RedSnow.parse(open('../contracts/edward/consume.mson').read)
full = RedSnow.parse(open('../explore/blueprint.apib').read)
tmp = ->{ RedSnow.parse(open('../contracts/tmp.mson').read) }

binding.pry
