# lita-puppet

TODO: Add a description of the plugin.

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
    puppet r10k [environment]

This is also available as:

    puppet deploy [environment]
    pp deploy [environment]
    pp r10k [environment]
