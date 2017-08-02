# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'state_machine_job/version'

Gem::Specification.new do |spec|
  spec.name          = "state_machine_job"
  spec.version       = StateMachineJob::VERSION
  spec.authors       = ["Codevise Solutions Ltd."]
  spec.email         = ["info@codevise.de"]
  spec.description   = %q{State Machine + Resque.}
  spec.summary       = %q{Resque jobs class for rails state machines.}
  spec.homepage      = "http://github.com/codevise/state_machine_job"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '< 13'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'activesupport', '< 5'
  spec.add_development_dependency 'semmy', '~> 1.0'

  spec.add_runtime_dependency 'resque', '~> 1.25'
  spec.add_runtime_dependency 'resque-logger', '~> 0.2.0'
  spec.add_runtime_dependency 'state_machine', '~> 1.2'
end
