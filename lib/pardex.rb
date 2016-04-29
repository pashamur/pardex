require_relative "pardex/version"
require_relative "pardex/table"
require_relative "pardex/log_parser"
require_relative "pardex/connection"
require 'pg_query'
require 'byebug'

LOG_FILE = "/usr/local/var/postgres/pg_log/ps_sample.log"

QUERIES_WITH_STATS = Pardex::LogParser.new.parse(LOG_FILE)
QUERIES = QUERIES_WITH_STATS.map{|q,i| i[:samples]}.inject(&:+)

DB_NAME = 'development_pasha' # Hardcoded for now
ALL_TABLES_QUERY = "SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_schema,table_name;"

module Pardex
  @@tables = Hash.new
  @@queries = Array.new
  @@conditions = Hash.new

  def self.run
    connection = Pardex::Connection.new(DB_NAME)
    tables = connection.execute(ALL_TABLES_QUERY).map{|r| r["table_name"]}

    tables.each do |table_name|
      tbl = Pardex::Table.new(table_name, connection)
      @@tables[table_name] = tbl
      @@conditions[table_name] = Hash.new
    end

    QUERIES.each do |query|
      add_query(query)
    end

    puts "Suggesting Indexes..."
    self.suggest_indexes
    byebug
  end

  def self.add_query(query)
    parsed = PgQuery.parse(query)
    return if parsed.tables.length < 1
    return if parsed.tables.select{|t| @@tables[t]}.count == 0 #Check that at least one of the tables in the query is in our working set.

    conditions = parsed.simple_where_conditions
    conditions.each do |cond|
      if parsed.tables.length == 1
        table = parsed.tables.first
        next if !@@conditions[table]

        @@conditions[table][cond] ||= [0, @@tables[table].selectivity(cond[0].split(".").reverse.first, cond[1], cond[2])]
        @@conditions[table][cond][0] += 1
      else # more than 1 table
        table = get_table(cond, parsed.tables)
        next if !@@conditions[table]

        @@conditions[table][cond] ||= [0, @@tables[table].selectivity(cond[0].split(".").reverse.first, cond[1], cond[2])]
        @@conditions[table][cond][0] += 1
      end
    end
  end

  def self.get_table(cond, tables)
    return cond[0].split(".").first if cond[0].split(".").length > 1

    tables.select{|t| @@tables[t].attributes.keys.include?(cond[0]) }.first
  end

  def self.suggest_indexes
    @@conditions.each do |table_name, table|
      table.each do |condition, (count, selectivity)|
        attribute = condition[0].split(".").reverse.first

        if selectivity < 0.1
          puts "Suggested Index on #{table_name}.#{attribute} WHERE #{condition.join(' ')} (selectivity: #{selectivity.round(5)})"
        end
      end
    end
  end

end
