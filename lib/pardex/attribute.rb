module Pardex
  class Attribute
    ATTRS = [:name, :null_frac, :most_common_vals, :most_common_freqs, :histogram_bounds].freeze
    THRESHOLD = 0.95

    ATTRS.each do |attrib|
      attr_accessor attrib
    end

    def initialize(stats, type)
      self.name = stats['attname']
      self.null_frac = stats['null_frac'].to_f
      self.most_common_vals = stats["most_common_vals"].gsub(/[{}]/,'').split(',') if stats["most_common_vals"]
      self.most_common_freqs = stats["most_common_freqs"].gsub(/[{}]/,'').split(',').map(&:to_f) if stats["most_common_freqs"]
      self.histogram_bounds = stats["histogram_bounds"].gsub(/[{}]/,'').split(',') if stats["histogram_bounds"]

      if type < ActiveRecord::Type::Integer
        self.most_common_vals = self.most_common_vals.map(&:to_i) if self.most_common_vals
        self.histogram_bounds = self.histogram_bounds.map(&:to_i) if self.histogram_bounds
      end
    end

    def is_pardex_candidate?
      null_frac_high? || skewed_distribution?
    end

    def candidate_reason
      return "Null Fraction" if null_frac_high?
      return "Skewed Distribution" if skewed_distribution?
    end

    def null_frac_high?
      return null_frac > THRESHOLD
    end

    def skewed_distribution?
      return most_common_freqs && (most_common_freqs.sum > THRESHOLD)
    end
  end
end