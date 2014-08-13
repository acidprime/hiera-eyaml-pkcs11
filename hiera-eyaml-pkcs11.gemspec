# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hiera/backend/eyaml/encryptors/pkcs11/version'

Gem::Specification.new do |spec|
  spec.name          = "hiera-eyaml-pkcs11"
  spec.version       = Hiera::Backend::Eyaml::Encryptors::Pkcs11::VERSION
  spec.authors       = ["Zachary Smith"]
  spec.email         = ["zack.smith@puppetlabs.com"]
  spec.summary       = %q{PKCS11 backend for hiera-eyaml}
  spec.description   = %q{PKCS11 backend for hiera-eyaml}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "pkcs11", "~> 0.2.4"
  spec.add_development_dependency "rake"

  spec.add_dependency "hiera-eyaml", "= 2.0.2"
end
