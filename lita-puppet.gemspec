Gem::Specification.new do |spec|
  spec.name          = 'lita-puppet'
  spec.version       = '0.6.2'
  spec.authors       = ['Daniel Schaaff', 'Jonathan Gnagy'].sort
  spec.email         = ['jgnagy@knuedge.com']
  spec.description   = 'Some basic Puppet interactions for Lita'
  spec.summary       = 'Allow the Lita bot to handle requests for puppet tasks'
  spec.homepage      = 'https://github.com/knuedge/lita-puppet'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '~> 4.7'
  spec.add_runtime_dependency 'rye'
  spec.add_runtime_dependency 'puppetdb-ruby'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rubocop'
end
