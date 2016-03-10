# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lacerda/version'

Gem::Specification.new do |spec|
  spec.name          = "lacerda"
  spec.version       = Lacerda::VERSION
  spec.authors       = ["Jannis Hermanns"]
  spec.email         = ["jannis@gmail.com"]

  spec.summary       = 'Markdown publish/consume contract parser and validator'
  spec.description   = 'Specify which objects your services publish or consume in MSON (markdown) and let this gem validate these contracts.'
  spec.homepage      = "https://github.com/moviepilot/lacerda"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = 'MIT'

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "rake",          ["~> 10.2"]

  # json-schema 2.6.0 validates differently than 2.5.1
  spec.add_runtime_dependency "json-schema"#,   ["~> 2.5.1"]

  spec.add_runtime_dependency "redsnow",       ["~> 0.4.3"]
  spec.add_runtime_dependency "colorize"
  spec.add_runtime_dependency "blumquist",     ["~> 0.4"]

  # Tins 1.7.0 is ruby 2.0 only
  spec.add_runtime_dependency "tins", ["~> 1.6.0"]

  spec.add_development_dependency "bundler",             ["~> 1"]
  spec.add_development_dependency "guard-bundler",       ["~> 2.1"]
  spec.add_development_dependency "guard-ctags-bundler", ["~> 1.4"]
  spec.add_development_dependency "guard-rspec",         ["~> 4.6"]
  spec.add_development_dependency "rspec",               ["~> 3.3"]
  spec.add_development_dependency "coveralls",           ["~> 0.8"]
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency 'pry'
  # spec.add_development_dependency 'pry-byebug'
  # spec.add_development_dependency 'pry-rescue'
  # spec.add_development_dependency 'pry-stack_explorer'
end
