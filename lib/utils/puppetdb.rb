module Utils
  # Utility methods for working with PuppetDB
  module PuppetDB
    def dbquery(url, q)
      # TODO: validate incoming query structure
      client = ::PuppetDB::Client.new(server: url)
      client.request *q
    end

    def node_roles_and_profiles(url, nodename)
      # TODO: validate url and nodename
      ::PuppetDB::Client.new(server: url) # this is weird but required
      d = ::PuppetDB::Client.get("/catalogs/#{nodename}")
      return d["error"] if d['error']

      tags = []
      d["data"]["resources"].each {|r| tags.concat(r['tags'])}

      # return all the tags related to profile:: or role::
      tags.sort.uniq.select {|t| t.match /^(profile|role)::/ }
    end
  end
end
