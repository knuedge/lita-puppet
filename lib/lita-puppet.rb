require 'lita'
require 'rye'
require 'timeout'
require 'resolv'
require 'puppetdb'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'utils/lita_puppet/puppetdb'
require 'utils/lita_puppet/ssh'
require 'utils/lita_puppet/text'
require 'lita/handlers/puppet'

Lita::Handlers::Puppet.template_root File.expand_path(
  File.join('..', '..', 'templates'),
  __FILE__
)
