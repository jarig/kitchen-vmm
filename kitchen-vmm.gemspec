# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'kitchen/driver/vmm_version'

Gem::Specification.new do |spec|
  spec.name          = "kitchen-vmm"
  spec.version       = Kitchen::Driver::VMM_VERSION
  spec.authors       = ["Jaroslav Gorjatsev"]
  spec.email         = ["gjarik@gmail.com"]
  spec.summary       = 'Virtual Machine Manager Driver for Test-Kitchen'
  spec.description   = 'Virtual Machine Manager Driver for Test-Kitchen'
  spec.homepage      = "https://github.com/jarig/kitchen-vmm"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "cane"
  spec.add_development_dependency "finstyle"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"

  spec.add_dependency "test-kitchen", "~> 1.4"
end
