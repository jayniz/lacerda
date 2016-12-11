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
  spec.add_runtime_dependency "rake"

  spec.add_runtime_dependency "json-schema",   ["~> 2.6.2"]

  spec.add_runtime_dependency "colorize"
  spec.add_runtime_dependency "blumquist",     ["~> 0.5"]

  spec.add_runtime_dependency "tins"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-ctags-bundler"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "codeclimate-test-reporter", ["~> 1.0"]
  spec.add_development_dependency 'pry'
end
