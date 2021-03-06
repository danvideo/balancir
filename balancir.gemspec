# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'balancir/version'

Gem::Specification.new do |gem|
  gem.name          = "balancir"
  gem.version       = Balancir::VERSION
  gem.authors       = ["Michael Brodhead", "Blaine Carlson"]
  gem.email         = ["mkb@orthogonal.org", "blaineosiris@comcast.net"]
  gem.description   = %q{A client side HTTP load balancer.}
  gem.summary       = %q{Allocate load between multiple instances of an HTTP service. } +
      %q{Remove non-functioning servers from rotation and add them back when they become available.}
  gem.homepage      = "https://github.com/mkb/balancir"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version     = '>= 1.9.2'

  gem.add_dependency('rack-client')
  gem.add_dependency('excon')
  gem.add_dependency('celluloid')

  gem.add_development_dependency('rspec')
  gem.add_development_dependency('sinatra')
  gem.add_development_dependency('realweb')
  gem.add_development_dependency('awesome_print')
  gem.add_development_dependency('colorize')
end
