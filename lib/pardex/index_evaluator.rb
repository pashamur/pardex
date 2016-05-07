require_relative 'index'

module Pardex
  class IndexEvaluator
    NUM_QUERY_RUNS = 3

    attr_accessor :index, :plan

    def evaluate(index, query)
      self.index = index

      # Get query timing without index
      before_time = get_average_query_time(query).round(3)

      index.create!

      index_used = index_used(query)
      after_time = get_average_query_time(query).round(3)

      index.drop!

      [before_time, after_time, index_used]
    end

    def percent_speed_improvement(index, query)
      before, after, used = evaluate(index, query)
      improvement = (before/after).round(3)

      return ['N', nil, nil, nil] unless used
      return ['Y', before, after, improvement]
    end

    def get_average_query_time(query)
      times = 1.upto(NUM_QUERY_RUNS).map{|i| get_query_timing(query)}
      average = times[1..NUM_QUERY_RUNS-1].reduce(&:+).to_f / times.count
    end

    def get_query_timing(query)
      table = index.table
      res = table.connection.execute("EXPLAIN (ANALYZE, FORMAT JSON) #{query};", true) # Need to force here to get accurate query info
      time = JSON.parse(res[0]["QUERY PLAN"]).first["Execution Time"].to_f # Execution time in ms
    end

    def index_used(query)
      table = index.table
      res = table.connection.execute("EXPLAIN (FORMAT JSON) #{query};")
      res[0]["QUERY PLAN"] =~ /#{index.name}/
    end
  end
end