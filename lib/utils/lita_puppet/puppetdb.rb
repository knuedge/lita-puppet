module Utils
  module LitaPuppet
    # Utility methods for working with PuppetDB
    module PuppetDB
      def class_nodes(url, classname)
        client = ::PuppetDB::Client.new({
                                          server: url,
                                          pem: {
                                            'key' => config.puppetdb_key,
                                            'cert'    => config.puppetdb_cert,
                                            'ca_file' => config.puppetdb_ca_cert
                                          }
                                        }, config.puppetdb_api_vers)
        q = client.request(
          'resources',
          [
            :and,
            [:'=', 'type', 'Class'],
            [:'=', 'title', classname.to_s]
          ]
        )

        q.data.map { |node| node['certname'] }
      end

      # rubocop:disable AbcSize
      def node_roles_and_profiles(url, what, nodename)
        # TODO: validate url and nodename
        ::PuppetDB::Client.new({
                                 server: url,
                                 pem: {
                                   'key' => config.puppetdb_key,
                                   'cert'    => config.puppetdb_cert,
                                   'ca_file' => config.puppetdb_ca_cert
                                 }
                               }, config.puppetdb_api_vers) # this is weird but required
        d = ::PuppetDB::Client.get("/catalogs/#{nodename}")
        return d['error'] if d['error']

        tags = []
        d['resources']['data'].each { |r| tags.concat(r['tags']) }

        # return all the tags related to profile:: or role::
        case what
        when 'profiles'
          tags.sort.uniq.select { |t| t.match(/^profile::/) }
        when 'roles'
          tags.sort.uniq.select { |t| t.match(/^role::/) }
        when 'r&p', 'p&r', 'roles and profiles'
          tags.sort.uniq.select { |t| t.match(/^(profile|role)::/) }
        end
      end
    end
  end
end
