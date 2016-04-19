require_relative 'attribute_stats'

module Pardex
  class Attribute
    attr_accessor :name, :stats

    def initialize(stats, rowcount, type, table)
      self.name = stats['attname']
      self.stats = AttributeStats.new(name, stats, rowcount, type, table)
    end

    def is_pardex_candidate?
      stats.null_frac_high? || stats.skewed_distribution?
    end

    def candidate_reason
      return "Null Fraction" if stats.null_frac_high?
      return "Skewed Distribution" if stats.skewed_distribution?
    end

    def selectivity(op, val)
      stats.selectivity(op, val)
    end
  end
end