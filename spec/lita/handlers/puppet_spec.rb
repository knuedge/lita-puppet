require 'spec_helper'
require 'pry'

describe Lita::Handlers::Puppet, lita_handler: true do
  before do
    registry.config.handlers.puppet.master_hostname = 'puppet.foo'
    registry.config.handlers.puppet.puppetdb_url = 'http://pboard.foo:8080'
  end

  let(:lita_user) { Lita::User.create('User', name: 'A User', mention_name: 'user') }

  let(:new_puppetdb_request_only) do
    instance_double('::PuppetDB::Client', request: puppetdb_nodes)
  end

  let(:puppetdb_nodes) do
    double(
      data: [
        { 'certname' => 'server1.foo' },
        { 'certname' => 'server2.foo' }
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
    allow(box).to receive(:[]).with('/opt/puppet/control').and_return(rye_box_git_only)
    box
  end

  let(:rye_box_git_only) { instance_double('Rye::Box', git: rye_output_git) }
  let(:rye_output_base) { double(exit_status: 0, stdout: ['foo'], stderr: ['bar']) }
  let(:rye_output_git) { double(exit_status: 0, stdout: ['Already up-to-date.'], stderr: []) }

  it 'should have the required routes' do
    is_expected.to route_command('puppet agent run on foo').to(:puppet_agent_run)
    is_expected.to route_command('puppet cert clean foo').to(:cert_clean)
    is_expected.to route_command('puppet profiles foo').to(:node_profiles)
    is_expected.to route_command('puppet class nodes foo').to(:nodes_with_class)
    is_expected.to route_command('puppet r10k').to(:r10k_deploy)
  end

  describe('#cert_clean') do
    it 'should clean a cert' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet cert clean server.name', as: lita_user)
      expect(replies[-2]).to eq('your `puppet cert clean` is all done!')
    end
  end

  describe('#puppet_agent_run') do
    it 'should run a puppet agent' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet agent run on server.name', as: lita_user)
      expect(replies[-2]).to eq('that puppet run is complete! It exited with status 0.')
    end
  end

  describe('#node_profiles') do
    it 'should provide a list of profiles and roles associated with a node' do
      allow(::PuppetDB::Client).to receive(:get).and_return(
        'data' => {
          'resources' => [
            { 'tags' => ['profile::foo'] },
            { 'tags' => ['role::baz'] }
          ]
        }
      )
      send_command('puppet roles and profiles foo', as: lita_user)
      expect(replies.last).to eq("/code profile::foo\nrole::baz")
    end
  end

  describe('#nodes_with_class') do
    it 'should provide a list of nodes containing a class' do
      allow(::PuppetDB::Client).to receive(:new).and_return(new_puppetdb_request_only)
      send_command('puppet class nodes profile::foo', as: lita_user)
      expect(replies.last).to eq("/code server1.foo\nserver2.foo")
    end
  end

  describe('#r10k_deploy') do
    it 'should trigger a git pull on the puppet master' do
      allow(Rye::Box).to receive(:new).and_return(rye_box)
      send_command('puppet deploy production', as: lita_user)
      expect(replies.last.split("\n").first).to eq('/code Already up-to-date.')
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
