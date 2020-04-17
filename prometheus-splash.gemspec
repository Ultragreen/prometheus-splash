# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'splash/constants'

Gem::Specification.new do |spec|
  spec.name          = "prometheus-splash"
  spec.version       = Splash::Constants::VERSION
  spec.authors       = [Splash::Constants::AUTHOR]
  spec.email         = [Splash::Constants::EMAIL]
  spec.description   = %q{Prometheus Logs and Batchs supervision over PushGateway and commands orchestration}
  spec.summary       = %q{Supervision with Prometheus of Logs and Asynchronous tasks orchestration for Services or Hosts }
  spec.homepage      = "http://www.ultragreen.net"
  spec.license       = Splash::Constants::LICENSE
  spec.require_paths << 'bin'
  spec.bindir = 'bin'
  spec.executables = Dir["bin/*"].map!{|item| item.gsub("bin/","")}
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'thor','~> 1.0.1'
  spec.add_runtime_dependency 'prometheus-client','~> 2.0.0'
  spec.add_runtime_dependency 'rufus-scheduler','~> 3.6.0'
  spec.add_runtime_dependency 'redis','~> 4.1.3'
  spec.add_runtime_dependency 'bunny','~> 2.15.0'
  spec.add_runtime_dependency 'ps-ruby','~> 0.0.4'
  spec.add_runtime_dependency 'tty-markdown','~> 0.6.0'
  spec.add_runtime_dependency 'tty-pager','~> 0.12.1'
  spec.add_runtime_dependency 'colorize','~> 0.8.1'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'rspec', '~> 3.9.0'
  spec.add_development_dependency 'yard', '~> 0.9.24'
  spec.add_development_dependency 'rdoc', '~> 6.2.1'
  spec.add_development_dependency 'roodi', '~> 5.0.0'
  spec.add_development_dependency 'code_statistics', '~> 0.2.13'
  spec.add_development_dependency 'yard-rspec', '~> 0.1'


end
