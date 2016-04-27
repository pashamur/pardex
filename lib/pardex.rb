require_relative "pardex/version"
require_relative "pardex/table"
require_relative "pardex/log_parser"
require 'active_record'
require 'pg_query'
require 'byebug'

LOG_FILE = "/usr/local/var/postgres/pg_log/postgresql-2016-04-25_000000.log"

QUERIES_WITH_STATS = Pardex::LogParser.new.parse(LOG_FILE)
QUERIES = QUERIES_WITH_STATS.map{|q,i| i[:samples]}.inject(&:+)

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

    self.suggest_indexes
    byebug
  end

  def self.add_query(query)
    parsed = PgQuery.parse(query)
    return if parsed.tables.length < 1

    load_unknown_tables(parsed.tables)
    conditions = parsed.simple_where_conditions
    conditions.each do |cond|
      if parsed.tables.length == 1
        table = parsed.tables.first
        @@conditions[table][cond] ||= [0, @@tables[table].selectivity(cond[0].split(".").reverse.first, cond[1], cond[2])]
        @@conditions[table][cond][0] += 1
      else # more than 1 table
        table = get_table(cond, parsed.tables)
        @@conditions[table][cond] ||= [0, @@tables[table].selectivity(cond[0].split(".").reverse.first, cond[1], cond[2])]
        @@conditions[table][cond][0] += 1
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

  def self.suggest_indexes
    @@conditions.each do |table_name, table|
      table.each do |condition, (count, selectivity)|
        if count > 1 && selectivity < 0.05
          puts "Suggested Index on #{table_name}.#{condition[0]} WHERE #{condition.join(' ')} (selectivity: #{selectivity.round(3)})"
        end
      end
    end
  end

end
