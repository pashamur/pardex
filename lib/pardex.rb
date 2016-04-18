require_relative "pardex/version"
require_relative "pardex/table"
require 'active_record'
require 'pg_query'
require 'byebug'

QUERIES = [
  "SELECT count(*) FROM users;",
  "SELECT count(*) FROM messages WHERE read IS TRUE;",
  "SELECT count(*) FROM messages WHERE read='t';",
].freeze

module Pardex
  @@tables = Hash.new
  @@queries = Array.new

  def self.included(klass)
    raise "Need ActiveRecord class but got #{klass}" unless klass <= ActiveRecord::Base

    table = Pardex::Table.new(klass)
    @@tables[klass.table_name] = table

    byebug
  end

  def self.add_query(query)
    parsed = PgQuery.parse(query)
    load_unknown_tables(parsed.tables)

    query = Pardex::Query.new(parsed, @@tables.map{|t| tables[t]})
    queries << query
  end

  def load_unknown_tables(tables)
    @@tables.each do |table|
      unless @@tables[table]
        @@tables[table] = Pardex::Table.new(table.classify.constantize)
      end
    end
  end
end
