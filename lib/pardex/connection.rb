require 'pg'

module Pardex
  class Connection
    attr_accessor :connection, :results

    def initialize(dbname, opts={})
      host = opts[:host] || nil
      port = opts[:port] || nil
      user = opts[:user] || nil
      password = opts[:password] || nil

      self.connection = PG::Connection.open(:host => host, :port => port, :dbname => dbname, :user => user, :password => password)
      self.results = Hash.new
    end

    def execute(query, force = false)
      return self.results[query] if !self.results[query].nil? && !force

      result = self.connection.exec(query)
      self.results[query] = result

      result
    end

    def close
      self.connection.close
    end
  end
end