# lita-puppet

[![Build Status](https://img.shields.io/travis/knuedge/lita-puppet/master.svg)](https://travis-ci.org/knuedge/lita-puppet)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://tldrlegal.com/license/mit-license)
[![RubyGems :: RMuh Gem Version](http://img.shields.io/gem/v/lita-puppet.svg)](https://rubygems.org/gems/lita-puppet)
[![Code Climate](https://img.shields.io/codeclimate/github/knuedge/lita-puppet.svg)](https://codeclimate.com/github/knuedge/lita-puppet)

A [Lita](https://www.lita.io/) handler plugin for some basic [Puppet](https://puppet.com/) operations.

## Installation

Add lita-puppet to your Lita instance's Gemfile:

``` ruby
gem "lita-puppet"
```

## Prerequisites

* Some of the commands require a [PuppetDB](https://docs.puppet.com/puppetdb/) server, and it must be specified in the configuration.
* Other commands require that Lita has SSH access to machines using an SSH key, and that Lita has Passwordless `sudo` capabilities. This sounds scary, but it can be done in a very restrictive way (and if you're using puppet, you can automate it).
* Lita authorization groups are used to restrict certain commands

## Configuration

* `config.handlers.puppet.master_hostname` - Puppet Master's hostname
* `config.handlers.puppet.puppetdb_url` - PuppetDB hostname (for the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem)
* `config.handlers.puppet.puppetdb_api_vers` - PuppetDB api version (for the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem)
* `config.handlers.puppet.puppetdb_key` - key file for puppetdb ssl (for the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem)
*  `config.handlers.puppet.puppetdb_cert` - cert file for puppetdb (for the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem)
* `config.handlers.puppet.puppetdb_ca_cert` - ca file for puppetdb (for the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem)
* `config.handlers.puppet.ssh_user` - SSH user for the Puppet Master for r10k deployments

### PuppetDB APIv4
If you are using this with version 4 of the PuppetDB api you append `/pdq/query` to the end of the PuppetDB server url. See [this issue for more info](https://github.com/voxpupuli/puppetdb-ruby/issues/13)

## Usage

#### Deploying an environment via r10k
    puppet r10k [environment [module]]
This requires the user is a member of the `puppet_admins` authorization group.

This is also available as:

    puppet deploy [environment [module]]
    pp deploy [environment [module]]
    pp r10k [environment [module]]


#### Trigger a manual run of the Puppet agent on a host
    puppet agent run on <host>
This requires the user is a member of the `puppet_admins` authorization group.

This is also available as:

    puppet run on <host>
    puppet run <host>
    pp agent run on <host>
    pp run on <host>
    pp on <host>

Though we don't recomend that last one...

#### Remove an SSL cert from the Puppet Master
    puppet cert clean <host>
This requires the user is a member of the `puppet_admins` authorization group.

This is also available as:

    pp cert clean <host>

**Note** though that this doesn't do anything on the client side. If you want puppet to work on the `<host>` machine you'll need to generate a new cert. Usually you run this if you're planning to do that anyway though.

#### Query PuppetDB for the Roles and Profiles used by a node
    puppet roles and profiles <certname>

This is also available as:

    puppet r&p <certname>
    puppet profiles <certname>
    puppet roles <certname>
    pp roles and profiles <certname>
    pp r&p <certname>
    pp profiles <certname>
    pp roles <certname>

Where `<certname>` is the SSL certificate name used for Puppet. This is usually the FQDN for the host. This query assumes you use the roles and profiles paradigm with the classes namespaced as `profile::example` and `role::example` etc.. Using only `roles` or `profiles` in the command will only return the requested information.

#### Query PuppetDB for the nodes associated with a class
    puppet class nodes <class>

This is also available as:

    pp class nodes <class>

Where `<class>` is a class name as it shows up in the catalog. Usually something like Role::Foo_bar
