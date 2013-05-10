# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'omudid'

Gem::Specification.new do |spec|
  spec.name          = "omudid"
  spec.version       = OneMoreUDID::VERSION
  spec.authors       = ["David Lawson"]
  spec.email         = ["tech.lawson@gmail.com"]
  spec.description   = 'Conveniently add a UDID to the iOS Developer Portal, refresh a provisioning profile and download it. Uploading a new provisioning profile to TestFlight is also supported.'
  spec.summary       = 'Add one UDID to iOS Dev Portal & TestFlight'
  spec.homepage      = 'https://github.com/Papercloud/OneMoreUDID'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "cupertino"

  spec.add_dependency "spinning_cursor"
  spec.add_dependency "rainbow"

  spec.add_dependency "commander", "~> 4.1.2"
end
