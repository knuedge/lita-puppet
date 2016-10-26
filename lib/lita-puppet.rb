require "lita"
require 'rye'
require 'timeout'

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/puppet"

Lita::Handlers::Puppet.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
