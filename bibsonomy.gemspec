# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bibsonomy/version'

Gem::Specification.new do |spec|
  spec.name          = "bibsonomy"
  spec.version       = BibSonomy::VERSION
  spec.authors       = ["Robert Jäschke"]
  spec.email         = ["jaeschke@l3s.de"]
  spec.summary       = %q{Wraps the BibSonomy REST API.}
  spec.description   = %q{Enables calls to the BibSonomy REST API with Ruby.}
  spec.homepage      = "https://github.com/rjoberon/bibsonomy-ruby"
  spec.license       = "LGPL-2.1-or-later"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 3.0'

  spec.add_development_dependency "bundler", "~> 2.4"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "minitest", "~> 6"
  spec.add_development_dependency "vcr", "~> 6"
  spec.add_development_dependency "webmock", "~> 3"
  spec.add_development_dependency "coveralls", '~> 0.7'
  spec.add_development_dependency "simplecov", '~> 0.9'
  spec.add_development_dependency "base64", '~> 0.3'

  spec.add_dependency "faraday", "~> 0.9"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "citeproc", "~> 1.0", '>= 1.0.9'
  spec.add_dependency "citeproc-ruby", "~> 1.0", '>= 1.1.10'
  spec.add_dependency "csl-styles", "~> 1.0"
  spec.add_dependency "csl", "~> 1.5"
  spec.add_dependency 'addressable', '~> 2.5'

end
