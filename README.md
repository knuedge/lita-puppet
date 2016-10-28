# lita-puppet

A [Lita](https://www.lita.io/) handler plugin for some basic [Puppet](https://puppet.com/) operations.

## Installation

Add lita-puppet to your Lita instance's Gemfile:

``` ruby
gem "lita-puppet"
```

## Configuration

* `config.handlers.puppet.control_repo_path` - Path for `git pull` during r10k deployments
* `config.handlers.puppet.master_hostname` - Puppet Master's hostname
* `config.handlers.puppet.puppetdb_url` - PuppetDB hostname (for the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem)
* `config.handlers.puppet.ssh_user` - SSH user for the Puppet Master for r10k deployments

## Usage

#### Deploying an environment via r10k
    puppet r10k [environment [module]]

This is also available as:

    puppet deploy [environment [module]]
    pp deploy [environment [module]]
    pp r10k [environment [module]]

#### Trigger a manual run of the Puppet agent on a host
    puppet agent run on <host>

This is also available as:

    puppet run on <host>
    puppet run <host>
    pp agent run on <host>
    pp run on <host>
    pp on <host>

Though we don't recomend that last one...

#### Remove an SSL cert from the Puppet Master
    puppet cert clean <host>

This is also available as:

    pp cert clean <host>

**Note** though that this doesn't do anything on the client side. If you want puppet to work on the `<host>` machine you'll need to generate a new cert. Usually you run this if you're planning to do that anyway though.

#### Query PuppetDB for the Roles and Profiles used by a node
    puppet catalog <certname> profiles

This is also available as:

    puppet node <certname> profiles
    pp catalog <certname> profiles
    pp node <certname> profiles

Where `<certname>` is the SSL certificate name used for Puppet. This is usually the FQDN for the host. This query assumes you use the roles and profiles paradigm with the classes namespaced as `profile::example` and `role::example` etc..

#### Query PuppetDB for all nodes with a given class in their catalog
`puppet class nodes <classname> `

Where `classname` is the name of the class you'd like to query for.
