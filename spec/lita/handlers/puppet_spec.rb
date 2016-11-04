require 'spec_helper'
require 'pry'

describe Lita::Handlers::Puppet, lita_handler: true do
  before do
    registry.config.handlers.puppet.master_hostname = 'puppet.foo'
    registry.config.handlers.puppet.puppetdb_url = 'http://pboard.foo:8080'

    # A ChatOpts user
    @user = Lita::User.create('User', name: 'A User', mention_name: 'user')

    # Stubs used throughout
    allow_any_instance_of(Rye::Box).to receive(:enable_sudo).and_return(true)
    allow_any_instance_of(Rye::Box).to receive(:disconnect).and_return(true)
    allow_any_instance_of(Rye::Box).to receive(:disable_safe_mode).and_return(true)
  end

  let(:base_rye_output) do
    double(exit_status: 0, stdout: ['foo'], stderr: ['bar'])
  end

  let(:puppetdb_nodes) do
    double(
      data: [
        { 'certname' => 'server1.foo' },
        { 'certname' => 'server2.foo' }
      ]
    )
  end

  it 'should have the required routes' do
    is_expected.to route_command('puppet agent run on foo').to(:puppet_agent_run)
    is_expected.to route_command('puppet cert clean foo').to(:cert_clean)
    is_expected.to route_command('puppet catalog foo profiles').to(:node_profiles)
    is_expected.to route_command('puppet class nodes foo').to(:nodes_with_class)
    is_expected.to route_command('puppet r10k').to(:r10k_deploy)
  end

  describe('#cert_clean') do
    before do
      # Stub out the SSH action via Rye::Box overrides
      allow_any_instance_of(Rye::Box).to receive(:cd).with('/tmp').and_return(true)
      allow_any_instance_of(Rye::Box).to receive(:execute).and_return(base_rye_output)
    end

    it 'should clean a cert' do
      send_command('puppet cert clean server.name', as: @user)
      expect(replies[-2]).to eq('your `puppet cert clean` is all done!')
    end
  end

  describe('#puppet_agent_run') do
    before do
      # Stub out the SSH action via Rye::Box overrides
      allow_any_instance_of(Rye::Box).to receive(:cd).with('/tmp').and_return(true)
      allow_any_instance_of(Rye::Box).to receive(:execute).and_return(base_rye_output)
    end

    it 'should run a puppet agent' do
      send_command('puppet agent run on server.name', as: @user)
      expect(replies[-2]).to eq('that puppet run is complete! It exited with status 0.')
    end
  end

  describe('#nodes_with_class') do
    before do
      allow_any_instance_of(::PuppetDB::Client).to receive(:request).and_return(puppetdb_nodes)
    end
    it 'should provide a lost of nodes containing a class in their catalog' do
      send_command('puppet class nodes profile::foo', as: @user)
      expect(replies.last).to eq("/code server1.foo\nserver2.foo")
    end
  end
end
