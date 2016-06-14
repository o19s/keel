# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'keel/version'

Gem::Specification.new do |spec|
  spec.name          = "keel"
  spec.version       = Keel::VERSION
  spec.authors       = ["Youssef Chaker"]
  spec.email         = ["ychaker@o19s.com"]

  spec.summary       = %q{Deploy your Rails app to Kubernetes.}
  spec.description   = %q{This gem lets you deploy your Rails application to your Kubernetes cluster.}
  spec.homepage      = "https://github.com/o19s/keel"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",  "~> 1.11"
  spec.add_development_dependency "rake",     "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  spec.add_runtime_dependency "inquirer",     "~> 0.2"
  spec.add_runtime_dependency "colorize",     "~> 0.7"
end
