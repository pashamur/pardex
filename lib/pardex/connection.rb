require 'pg'

module Pardex
  class Connection
    attr_accessor :connection, :results

    def initialize(dbname, opts={})
      raise 'Please specify database, host, port, and user when opening a Pardex::Connection' if dbname.nil? || !(%i{host port user}.select{|k| opts.has_key?(k)}.count == 3)
      host = opts[:host]
      port = opts[:port]
      user = opts[:user]

      self.connection = PG::Connection.open(:host => host, :port => port, :dbname => dbname, :user => user)
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