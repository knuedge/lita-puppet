# lita-puppet

A [Lita](https://www.lita.io/) handler plugin for some basic [Puppet](https://puppet.com/) operations.

## Installation

Add lita-puppet to your Lita instance's Gemfile:

``` ruby
gem "lita-puppet"
```

## Configuration

* `config.handlers.puppet.master_hostname` - Puppet Master's hostname
* `config.handlers.puppet.ssh_user` - SSH user for the Puppet Master for r10k deployments
* `config.handlers.puppet.control_repo_path` - Path for `git pull` during r10k deployments

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
