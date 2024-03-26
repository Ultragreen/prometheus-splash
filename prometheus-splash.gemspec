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
  spec.homepage      = "https://github.com/Ultragreen/prometheus-splash"
  spec.license       = Splash::Constants::LICENSE
  spec.require_paths << 'bin'
  spec.bindir = 'bin'
  spec.executables = Dir["bin/*"].map!{|item| item.gsub("bin/","")}
  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'thor','~> 1.3.1'
  spec.add_runtime_dependency 'prometheus-client','~> 4.2.2'
  spec.add_runtime_dependency 'rufus-scheduler','~> 3.9.1'
  spec.add_runtime_dependency 'redis','~> 5.1.0'
  spec.add_runtime_dependency 'bunny','~> 2.22.0'
  spec.add_runtime_dependency 'ps-ruby','~> 0.0.4'
  spec.add_runtime_dependency 'tty-markdown','~> 0.7.2'
  spec.add_runtime_dependency 'tty-pager','~> 0.14.0'
  spec.add_runtime_dependency 'tty-table','~> 0.12.0'
  spec.add_runtime_dependency 'net-ssh','~> 7.2.1'
  spec.add_runtime_dependency 'net-scp','~> 4.0.0'
  spec.add_runtime_dependency 'colorize','~> 1.1.0'
  spec.add_runtime_dependency 'sinatra','~> 4.0.0'
  spec.add_runtime_dependency 'thin'
  spec.add_runtime_dependency 'rack', '~> 3.0.10'
  spec.add_runtime_dependency 'rest-client','~> 2.1.0'
  spec.add_runtime_dependency 'slim','~> 5.2.1'
  spec.add_runtime_dependency 'kramdown','~> 2.4.0'
  spec.add_runtime_dependency 'rack-reverse-proxy','~> 0.12.0'

  spec.add_development_dependency 'rake', '~> 13.1.0'
  spec.add_development_dependency 'rspec', '~> 3.13.0'
  spec.add_development_dependency 'yard', '~> 0.9.36'
  spec.add_development_dependency 'rdoc', '~> 6.6.3.1'
  spec.add_development_dependency 'roodi', '~> 5.0.0'
  spec.add_development_dependency 'code_statistics', '~> 0.2.13'
  spec.add_development_dependency 'yard-rspec', '~> 0.1'
  spec.add_development_dependency 'bundler', '~> 2.5.7'

end
