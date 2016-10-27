require "lita"
require 'rye'
require 'timeout'
require 'puppetdb'

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require 'utils/puppetdb'
require 'utils/ssh'
require 'utils/text'
require "lita/handlers/puppet"

Lita::Handlers::Puppet.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
