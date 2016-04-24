require_relative "pardex/version"
require_relative "pardex/table"
require 'active_record'
require 'pg_query'
require 'byebug'

QUERIES = [
  "SELECT count(*) FROM users",
  "SELECT count(*) FROM users WHERE first_name = 'Roger'",
  "SELECT count(*) FROM messages WHERE read IS TRUE",
  "SELECT count(*) FROM messages WHERE read IS TRUE",
  "SELECT count(*) FROM messages WHERE read = 't'",
].freeze

# Desired output:
# conditions = {
#   'users' => {
#     ['first_name', '=', 'Roger'] => 1
#   },
#   'messages' => {
#     ['read', 'IS', true] => 2,
#     ['read', '=', true] => 1
#   }
# }
#

module Pardex
  @@tables = Hash.new
  @@queries = Array.new
  @@conditions = Hash.new

  def self.included(klass)
    raise "Need ActiveRecord class but got #{klass}" unless klass <= ActiveRecord::Base

    table = Pardex::Table.new(klass)
    @@tables[klass.table_name] = table
    @@conditions[klass.table_name] = Hash.new

    QUERIES.each do |query|
      add_query(query)
    end

    byebug
  end

  def self.add_query(query)
    parsed = PgQuery.parse(query)
    return if parsed.tables.length < 1

    load_unknown_tables(parsed.tables)
    conditions = parsed.simple_where_conditions
    conditions.each do |cond|
      if parsed.tables.length == 1
        @@conditions[parsed.tables.first][cond] ||= 0
        @@conditions[parsed.tables.first][cond] += 1
      else # more than 1 table
        @@conditions[get_table(cond, parsed.tables)][cond] ||= 0
        @@conditions[get_table(cond, parsed.tables)][cond] += 1
      end
    end
  end

  def self.get_table(cond, tables)
    return cond[0].split(".").first if cond[0].split(".").length > 1

    tables.select{|t| t.attributes.keys.include?(cond[0]) }.first
  end

  def self.load_unknown_tables(tables)
    tables.each do |table|
      unless @@tables[table]
        @@tables[table] = Pardex::Table.new(table.classify.constantize)
        @@conditions[table] = Hash.new
      end
    end
  end

end
