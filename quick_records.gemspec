require_relative 'lib/quick_records/version'

Gem::Specification.new do |spec|
  spec.name        = 'quick_records'
  spec.version     = QuickRecords::VERSION
  spec.authors     = ['calebanderson']
  spec.email       = ['caleb.r.anderson.1@gmail.com']
  spec.homepage    = 'https://github.com/calebanderson/quick_records'
  spec.summary     = 'Smart-ish helpers for record finding, keeping, and reloading'
  spec.description = 'Smart-ish helpers for record finding, keeping, and reloading'
  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = 'TODO: Set to http://mygemserver.com'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/calebanderson/quick_records'
  spec.metadata['changelog_uri'] = 'https://github.com/calebanderson/quick_records/blob/master/CHANGELOG.md'

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 4.2'
  spec.add_dependency 'responsive_console'
  spec.add_dependency 'shared_helpers'
end
