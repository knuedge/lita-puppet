require 'spec_helper'

describe Lita::Handlers::Puppet, lita_handler: true do
  it 'routes agent run commands properly' do
    is_expected.to route_command('puppet agent run on foo').to(:puppet_agent_run)
  end

  it 'routes cert clean commands properly' do
    is_expected.to route_command('puppet cert clean foo').to(:cert_clean)
  end

  it 'routes catalog profiles commands properly' do
    is_expected.to route_command('puppet catalog foo profiles').to(:node_profiles)
  end

  it 'routes class nodes commands properly' do
    is_expected.to route_command('puppet class nodes foo').to(:nodes_with_class)
  end

  it 'routes r10k commands properly' do
    is_expected.to route_command('puppet r10k').to(:r10k_deploy)
  end
end
