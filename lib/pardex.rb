require_relative "pardex/version"
require_relative "pardex/table"
require_relative "pardex/log_parser"
require_relative "pardex/connection"
require_relative "pardex/index_evaluator"
require 'pg_query'
require 'byebug'

ALL_TABLES_QUERY = "SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_schema,table_name;"

module Pardex
  @@tables = Hash.new
  @@conditions = Hash.new

  def self.run(opts)
    connection = Pardex::Connection.new(opts[:db_name], {:host => opts[:db_host], :port => opts[:db_port], :user => opts[:db_user], :password => opts[:db_password]})
    @@table_names = Set.new(connection.execute(ALL_TABLES_QUERY).map{|r| r["table_name"]})

    queries_with_stats = Pardex::LogParser.new.parse(opts[:log_file], opts[:db_name])
    queries = queries_with_stats.select{|k,v| k[0..5] == "SELECT"}.map{|q,i| i[:samples]}.inject(&:+)

    queries.each do |query|
      add_query(query, connection)
    end

    puts "Suggesting Indexes..."
    puts ""
    self.suggest_indexes
  end

  def self.add_query(query, connection)
    parsed = PgQuery.parse(query)
    parsed_tables = parsed.tables
    return if parsed_tables.length < 1
    #Check that at least one of the tables in the query is in our working set.
    return if !Set.new(parsed_tables).intersect? @@table_names

    # Load tables which are relevant. -- should probably filter at log level as well.
    parsed_tables.select{|t| @@table_names.include?(t) && !@@tables.include?(t)}.each do |table|
      @@tables[table] = Pardex::Table.new(table, connection)
      @@conditions[table] = Hash.new
    end

    conditions = parsed.simple_where_conditions

    conditions.each do |cond|
      if parsed.tables.length == 1
        table = parsed.tables.first
        next if !@@conditions[table]

        selectivity = @@tables[table].selectivity(cond[0].split(".").reverse.first, cond[1], cond[2])

        @@conditions[table][cond] ||= [0, selectivity, Array.new]
        @@conditions[table][cond][0] += 1
        @@conditions[table][cond][2] << query
      else # more than 1 table
        table = get_table(cond, parsed.tables)
        next if !@@conditions[table]

        selectivity = @@tables[table].selectivity(cond[0].split(".").reverse.first, cond[1], cond[2])
        @@conditions[table][cond] ||= [0, selectivity, Array.new]
        @@conditions[table][cond][0] += 1
        @@conditions[table][cond][2] << query
      end
    end
  end

  def self.get_table(cond, tables)
    return cond[0].split(".").first if cond[0].split(".").length > 1

    tables.select{|t| @@tables[t].attributes && @@tables[t].attributes.keys.include?(cond[0]) }.first
  end

  def self.suggest_indexes
    @@conditions.each do |table_name, table|
      table.each do |condition, (count, selectivity, queries)|
        attribute = condition[0].split(".").reverse.first

        if (count > 1) && selectivity && (selectivity < 0.1 && selectivity > 0)
          puts "Suggested Index on #{table_name}.#{attribute} WHERE #{condition.join(' ')} (count: #{count}, selectivity: #{selectivity})"

          _, op, val = condition
          quoted_val = (val.is_a?(String) && !(['true','false','null'].include?(val.downcase)) && op != "IN" ? "'#{val}'" : val)

          index = Pardex::Index.new(@@tables[table_name], attribute, "#{attribute} #{op} #{quoted_val}")
          eval = Pardex::IndexEvaluator.new.evaluate(index, queries.first)
        end
      end
    end
  end

end
