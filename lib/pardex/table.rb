require_relative 'attribute'

module Pardex
  class Table
    attr_accessor :name, :statistics, :attributes

    def initialize(model)
      self.name = model.table_name
      self.statistics = model.connection.execute "SELECT * FROM pg_stats WHERE tablename='#{model.table_name}'"
      self.attributes = statistics.map do |stats|
        name = stats["attname"]
        ar_info = model.columns_hash[name]
        ar_column_type = ar_info.cast_type.class

        Attribute.new(stats, ar_column_type)
      end
    end

    def candidates
      attributes.select(&:is_pardex_candidate?).map{|a| [a.name, a.candidate_reason]}
    end
  end
end