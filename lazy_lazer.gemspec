# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lazy_lazer/version'

Gem::Specification.new do |spec|
  spec.name     = 'lazy_lazer'
  spec.version  = LazyLazer::VERSION
  spec.authors  = ['Avinash Dwarapu']
  spec.email    = ['avinash@dwarapu.me']

  spec.summary  = 'Create lazily loadable models.'
  spec.homepage = 'https://github.com/avinashbot/lazy_lazer'
  spec.license  = 'MIT'
  spec.required_ruby_version = '>= 2.1.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 12.1'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop', '~> 0.50'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
end
