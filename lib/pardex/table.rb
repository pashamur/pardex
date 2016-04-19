require_relative 'attribute'

module Pardex
  class Table
    attr_accessor :name, :connection, :statistics, :rowcount, :attributes

    def initialize(model)
      self.name = model.table_name
      self.connection = model.connection
      self.statistics = connection.execute "SELECT * FROM pg_stats WHERE tablename='#{model.table_name}'"
      row_result = connection.exec_query(row_number_query)
      self.rowcount = ("%f" % row_result.first["reltuples"]).to_i # Approximate rowcount - same as used by postgres planner
      self.attributes = statistics.map do |stats|
        name = stats["attname"]
        ar_info = model.columns_hash[name]
        ar_column_type = ar_info.cast_type.class

        {name => Attribute.new(stats, rowcount, ar_column_type, self)}
      end.inject(&:merge!)
    end

    def candidates
      attributes.select(&:is_pardex_candidate?).map{|a| [a.name, a.candidate_reason]}
    end

    def selectivity(attribute, op, val)
      attributes[attribute].selectivity(op, val)
    end

    def row_number_query
      " SELECT nspname AS schemaname,relname,reltuples
        FROM pg_class C
        LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
        WHERE relname = '#{self.name}'; "
    end
  end
end