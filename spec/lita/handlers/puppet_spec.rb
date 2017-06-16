require 'spec_helper'
require 'pry'

describe Lita::Handlers::Puppet, lita_handler: true do
  before do
    registry.config.handlers.puppet.master_hostname = 'puppet.foo'
    registry.config.handlers.puppet.puppetdb_url = 'https://pboard.foo:8081'
    registry.config.handlers.puppet.puppetdb_key = 'keyfile'
    registry.config.handlers.puppet.puppetdb_cert = 'certfile'
    registry.config.handlers.puppet.puppetdb_ca_cert = 'cafile'
  end

  let(:lita_user) { Lita::User.create('User', name: 'A User', mention_name: 'user') }

  let(:new_puppetdb_request_only) do
    instance_double('::PuppetDB::Client', request: puppetdb_nodes)
  end

  let(:fact_request) do
    instance_double('::PuppetDB::Client', request: puppetdb_fact_result)
  end

  let(:info_request) do
    instance_double('::PuppetDB::Client', request: puppetdb_host_info)
  end

  let(:bad_request) do
    instance_double('::PuppetDB::Client', request: puppetdb_nil_data)
  end

  let(:puppetdb_nodes) do
    double(
      data: [
        { 'certname' => 'server1.foo' },
        { 'certname' => 'server2.foo' }
      ]
    )
  end

  let(:puppetdb_nil_data) do
    double(
      data: [
      ]
    )
  end
  let(:puppetdb_host_info) do
    double(
      data: [
        { 'deactivated' => nil,
          'latest_report_hash' => '693feed',
          'facts_environment' => 'production' }
      ]
    )
  end

  let(:puppetdb_fact_result) do
    double(
      data: [
        {
          'certname' => 'foo.example.com',
          'name' => 'operatingsystem',
          'value' => 'Darwin',
          'environment' => 'production'
        }
      ]
    )
  end

  let(:rye_box) do
    box = instance_double(
      'Rye::Box',
      disable_safe_mode: true,
      disconnect: true,
      enable_sudo: true,
      execute: rye_output_base
    )
    allow(box).to receive(:cd).with('/tmp').and_return(true)
    box
  end

  let(:rye_output_base) { double(exit_status: 0, stdout: ['foo'], stderr: ['bar']) }

  it 'should have the required routes' do
    is_expected.to route_command('puppet agent run on foo')
      .with_authorization_for(:puppet_admins).to(:puppet_agent_run)
    is_expected.to route_command('puppet cert clean foo')
      .with_authorization_for(:puppet_admins).to(:cert_clean)
    is_expected.to route_command('puppet profiles foo').to(:node_profiles)
    is_expected.to route_command('puppet class nodes foo').to(:nodes_with_class)
    is_expected.to route_command('puppet r10k')
      .with_authorization_for(:puppet_admins).to(:r10k_deploy)
    is_expected.to route_command('puppet fact node foo').to(:node_facts)
    is_expected.to route_command('puppet node info').to(:nodes_info)
  end

  describe('#cert_clean') do
    before do
      robot.auth.add_user_to_group!(lita_user, :puppet_admins)
    end
    it 'should clean a cert' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet cert clean server.name', as: lita_user)
      expect(replies[-2]).to eq('your `puppet cert clean` is all done!')
    end
  end

  describe('#puppet_agent_run') do
    let(:rye_output_base) do
      double(exit_status: 0, stdout: (0..99).to_a, stderr: ['bar'])
    end

    before do
      robot.auth.add_user_to_group!(lita_user, :puppet_admins)
    end

    it 'notifies users when server names are not resolvable' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet agent run on server.name', as: lita_user)
      expect(replies[-1]).to eq('I couldn\'t find a machine called \'server.name\'.')
    end

    it 'should run a puppet agent' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet agent run on localhost', as: lita_user)
      expect(replies[-2]).to eq('that puppet run is complete! It exited with status 0.')
    end

    it 'should truncate long results' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet agent run on localhost', as: lita_user)
      expect(replies[-1].lines.last).to eq('... truncated to 50 lines')
      expect(replies[-1].lines.size).to eq(51)
    end
  end

  describe('#node_profiles') do
    it 'should provide a list of profiles and roles associated with a node' do
      allow(::PuppetDB::Client).to receive(:get).and_return(
        'resources' => {
          'data' => [
            { 'tags' => ['profile::foo'] },
            { 'tags' => ['role::baz'] }
          ]
        }
      )
      send_command('puppet roles and profiles foo', as: lita_user)
      expect(replies.last).to eq("/code profile::foo\nrole::baz")
    end
    it 'should return error for no profile or role tags' do
      allow(::PuppetDB::Client).to receive(:get).and_return(
        'resources' => {
          'data' => [
            { 'tags' => ['baz::foo'] },
            { 'tags' => ['bar::baz'] }
          ]
        }
      )
      send_command('puppet roles and profiles foo', as: lita_user)
      expect(replies.last).to eq("The catalog did not contain any roles or profiles for 'foo'")
    end
  end

  describe('#nodes_with_class') do
    it 'should provide a list of nodes containing a class' do
      allow(::PuppetDB::Client).to receive(:new).and_return(new_puppetdb_request_only)
      send_command('puppet class nodes profile::foo', as: lita_user)
      expect(replies.last).to eq("/code server1.foo\nserver2.foo")
    end
  end

  describe('#node_facts') do
    it 'should return error msg for invalid certname' do
      allow(::PuppetDB::Client).to receive(:new).and_return(bad_request)
      send_command('puppet fact foo.example.com operatingsystem')
      expect(replies.last)
        .to eq("that didn't work, are you sure foo.example.com is a valid certname?")
    end
    it 'should return error msg for invalid certname' do
      allow(::PuppetDB::Client).to receive(:new).and_return(fact_request)
      send_command('puppet fact foo.example.com operatingsystem')
      expect(replies.last).to eq('Darwin')
    end
  end

  describe('#nodes_info') do
    it 'should return error msg for invalid certname' do
      allow(::PuppetDB::Client).to receive(:new).and_return(bad_request)
      send_command('puppet foo.example.com info')
      expect(replies.last)
        .to eq("that didn't work, are you sure foo.example.com is a valid certname?")
    end
    it 'should return the node info' do
      allow(::PuppetDB::Client).to receive(:new).and_return(info_request)
      send_command('puppet foo.example.com info')
      expect(replies.last)
        .to eq("---\ndeactivated: \nlatest_report_hash: 693feed\nfacts_environment: production\n")
    end
  end

  describe('#r10k_deploy') do
    before do
      robot.auth.add_user_to_group!(lita_user, :puppet_admins)
    end
    context 'without a module or environment' do
      it 'should trigger r10k on the puppet master' do
        allow(Rye::Box).to receive(:new).and_return(rye_box)
        send_command('puppet deploy', as: lita_user)
        expect(replies[-2]).to eq('your r10k deployment is done!')
      end
    end
    context 'with an environment and no module' do
      it 'should trigger r10k on the puppet master' do
        allow(Rye::Box).to receive(:new).and_return(rye_box)
        send_command('puppet deploy production', as: lita_user)
        expect(replies[-2]).to eq('your r10k deployment is done!')
      end
    end
    context 'with an environment and a module' do
      it 'should trigger r10k on the puppet master' do
        allow(Rye::Box).to receive(:new).and_return(rye_box)
        send_command('puppet deploy production role', as: lita_user)
        expect(replies[-2]).to eq('your r10k deployment is done!')
      end
    end
  end
end
