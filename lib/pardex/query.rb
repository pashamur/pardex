require_relative 'table'

# Tables are of type Pardex::Table
module Pardex
  class Query
    attr_accessor :pg_query, :tables

    def initialize(pg_query, tables)
      self.pg_query = pg_query
      self.tables = tables
    end
  end
end