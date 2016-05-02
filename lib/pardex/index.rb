module Pardex
  class Index
    attr_accessor :table, :columns, :condition, :name

    def initialize(table, columns, condition, name=nil)
      self.table = table
      self.columns = Array(columns)
      self.condition = condition
      self.name = name || "#{table.name}_#{self.columns.join('_')}_idx_#{Digest::MD5.hexdigest(condition)[0...10]}"
    end

    def create!
      # puts "Creating index #{name} ON #{table.name} (#{columns.join(',')}) #{condition ? ' WHERE ' + condition : ''}"
      table.connection.execute(create_sql)
    end

    def drop!
      # puts "Dropping index #{name}"
      res = table.connection.execute(drop_sql)
    end

    def create_sql
      "CREATE INDEX CONCURRENTLY #{name} ON #{table.name} (#{columns.join(',')}) #{condition ? ' WHERE ' + condition : ''}"
    end

    def drop_sql
      "DROP INDEX CONCURRENTLY #{name}"
    end

    def size
      stats["index_size"]
    end

    def table_num_rows
      stats["table_num_rows"]
    end

    def table_size
      stats["table_size"]
    end

    def unique?
      stats["unique"] == "Y" ? true : false
    end

    def stats
      @_stats ||= table.connection.execute(stats_query)
      @_stats[0]
    end

    def stats_query
      "
      SELECT
            t.tablename,
            indexname,
            c.reltuples AS num_rows,
            pg_size_pretty(pg_relation_size(quote_ident(t.tablename)::text)) AS table_size,
            pg_size_pretty(pg_relation_size(quote_ident(indexrelname)::text)) AS index_size,
            CASE WHEN indisunique THEN 'Y'
               ELSE 'N'
            END AS UNIQUE,
            idx_scan AS number_of_scans,
            idx_tup_read AS tuples_read,
            idx_tup_fetch AS tuples_fetched
        FROM pg_tables t
        JOIN pg_class c ON t.tablename=c.relname
        JOIN
            ( SELECT c.relname AS ctablename, ipg.relname AS indexname, x.indnatts AS number_of_columns, idx_scan, idx_tup_read, idx_tup_fetch, indexrelname, indisunique FROM pg_index x
                   JOIN pg_class c ON c.oid = x.indrelid
                   JOIN pg_class ipg ON ipg.oid = x.indexrelid
                   JOIN pg_stat_all_indexes psai ON x.indexrelid = psai.indexrelid
                   WHERE ipg.relname = '#{name}' )
            AS foo
            ON t.tablename = foo.ctablename
        WHERE t.schemaname='public'
        ORDER BY 1,2;
      "
    end
  end
end