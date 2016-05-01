require_relative 'attribute'

module Pardex
  class Table
    attr_accessor :name, :connection, :statistics, :rowcount, :attributes

    def initialize(table_name, connection)
      self.name = table_name
      self.connection = connection
      self.statistics = connection.execute(stats_and_type_query)
      row_result = connection.execute(row_number_query)
      self.rowcount = row_result.first["reltuples"].to_i # Approximate rowcount - same as used by postgres planner
      self.attributes = statistics.map do |stats|
        name = stats["attname"]
        type = stats["data_type"]

        {name => Attribute.new(stats, rowcount, type, self)}
      end.inject(&:merge!)
    end

    def candidates
      attributes.select(&:is_pardex_candidate?).map{|a| [a.name, a.candidate_reason]}
    end

    def selectivity(attribute, op, val)
      return 0 unless attributes && attributes[attribute]
      attributes[attribute].selectivity(op, val)
    end

    def row_number_query
      " SELECT nspname AS schemaname,relname,reltuples
        FROM pg_class C
        LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
        WHERE relname = '#{self.name}'; "
    end

    def stats_and_type_query
      "SELECT ISC.data_type, PGS.*
       FROM information_schema.columns ISC
       LEFT JOIN pg_stats PGS
       ON ISC.column_name = PGS.attname
       WHERE PGS.tablename = '#{self.name}'
       AND ISC.table_name = '#{self.name}';"
    end
  end
end