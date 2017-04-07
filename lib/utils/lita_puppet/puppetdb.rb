module Utils
  module LitaPuppet
    # Utility methods for working with PuppetDB
    module PuppetDB
      def db_connect
        ::PuppetDB::Client.new({
                                 server: config.puppetdb_url,
                                 pem: {
                                   'key' => config.puppetdb_key,
                                   'cert'    => config.puppetdb_cert,
                                   'ca_file' => config.puppetdb_ca_cert
                                 }
                               }, config.puppetdb_api_vers)
      end

      def class_nodes(classname)
        q = db_connect.request(
          'resources',
          [
            :and,
            [:'=', 'type', 'Class'],
            [:'=', 'title', classname.to_s]
          ]
        )

        q.data.map { |node| node['certname'] }
      end

      def query_fact(node, fact)
        q = db_connect.request(
          "facts/#{fact}",
          [:'=', 'certname', node]
        )
        begin
          raise 'invalid query' if q.data.empty?
          q.data.empty? raise 'invalid query'
          q.data.last['value']
        rescue
          nil
        end
      end

      def node_info(node)
        q = db_connect.request(
          'nodes',
          [:'=', 'certname', node]
        )
        begin
          raise 'invalid node' if q.data.empty?
          q.data.last.to_yaml
        rescue
          nil
        end
      end

      # rubocop:disable AbcSize
      def node_roles_and_profiles(what, nodename)
        # TODO: validate url and nodename
        ::PuppetDB::Client.new({
                                 server: config.puppetdb_url,
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
