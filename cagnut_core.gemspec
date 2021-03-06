# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cagnut/version'

Gem::Specification.new do |spec|
  spec.name          = "cagnut_core"
  spec.version       = CagnutCore::VERSION
  spec.authors       = ['Shi-Gang Wang', 'Tse-Ching Ho']
  spec.email         = ['seanwang@goldenio.com', 'tsechingho@goldenio.com']

  spec.summary       = %q{Computational and Analytical Gear for Nucleic acid Utilitarian Techniques}
  spec.description   = %q{Computational and Analytical Gear for Nucleic acid Utilitarian Techniques}
  spec.homepage      = "https://github.com/CAGNUT/cagnut_core"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '> 5'
  spec.add_dependency 'tilt'
  spec.add_dependency 'thor'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
