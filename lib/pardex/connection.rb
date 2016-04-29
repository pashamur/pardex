require 'pg'

module Pardex
  class Connection
    attr_accessor :connection, :results

    def initialize(dbname, opts={})
      raise 'Please specify database name when opening a Pardex::Connection' if dbname.nil?
      host = opts[:host] || 'localhost'
      port = opts[:port] || 5432

      self.connection = PG::Connection.open(:host => host, :port => port, :dbname => dbname)
      self.results = Hash.new
    end

    def execute(query, force = false)
      return self.results[query] if !self.results[query].nil? && !force

      result = self.connection.exec(query)
      self.results[query] = result

      result
    end
  end
end