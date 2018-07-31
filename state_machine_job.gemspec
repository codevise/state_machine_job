# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'state_machine_job/version'

Gem::Specification.new do |spec|
  spec.name          = "state_machine_job"
  spec.version       = StateMachineJob::VERSION
  spec.authors       = ["Codevise Solutions Ltd."]
  spec.email         = ["info@codevise.de"]
  spec.description   = %q{State Machine + Active Job}
  spec.summary       = %q{Trigger jobs via Rails state machines.}
  spec.homepage      = "http://github.com/codevise/state_machine_job"
  spec.licenses    = ['MIT']

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'state_machines-activemodel', '~> 0.5.0'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '< 13'
  spec.add_development_dependency 'rspec-rails', '~> 3.7'
  spec.add_development_dependency 'activesupport', '< 6'
  spec.add_development_dependency 'activemodel', '< 6'
  spec.add_development_dependency 'semmy', '~> 1.0'
  spec.add_development_dependency 'timecop', '~> 0.9.1'

  spec.add_runtime_dependency 'activejob', ['>= 4.2', '< 6']
  spec.add_runtime_dependency 'state_machines', '~> 0.5.0'
end
