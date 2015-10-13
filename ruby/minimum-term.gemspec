# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'minimum_term/version'

Gem::Specification.new do |spec|
  spec.name          = "minimum-term"
  spec.version       = MinimumTerm::VERSION
  spec.authors       = ["Jannis Hermanns"]
  spec.email         = ["jannis@gmail.com"]

  spec.summary       = 'Markdown publish/consume contract parser and validator'
  spec.description   = 'Specify which objects your services publish or consume in MSON (markdown) and let this gem validate these contracts.'
  spec.homepage      = "https://github.com/moviepilot/minimum-term"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "http://gems.moviepilot.com"
  end

  spec.add_runtime_dependency "activesupport", "~> 4.2"
  spec.add_runtime_dependency "rake",          "~> 10.2"
  spec.add_runtime_dependency "json-schema",   "~> 2.5"

  spec.add_development_dependency "bundler",   "~> 1"
  spec.add_development_dependency "guard-bundler",       "~> 2.1"
  spec.add_development_dependency "guard-ctags-bundler", "~> 1.4"
  spec.add_development_dependency "guard-rspec",         "~> 4.6"
  spec.add_development_dependency "rspec",               "~> 3.3"
  spec.add_development_dependency "simplecov-rcov",      "~> 0.2"
  spec.add_development_dependency "fuubar",              "~> 2.0"


end
