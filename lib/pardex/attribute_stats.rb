module Pardex
  class AttributeStats
    THRESHOLD = 0.95
    attr_accessor :null_frac, :most_common_vals, :most_common_freqs, :histogram_bounds, :n_distinct, :rowcount

    def initialize(stats, rowcount, type)
      self.null_frac = stats['null_frac'].to_f
      self.most_common_vals = stats["most_common_vals"].gsub(/[{}]/,'').split(',') if stats["most_common_vals"]
      self.most_common_freqs = stats["most_common_freqs"].gsub(/[{}]/,'').split(',').map(&:to_f) if stats["most_common_freqs"]
      self.histogram_bounds = stats["histogram_bounds"].gsub(/[{}]/,'').split(',') if stats["histogram_bounds"]
      self.n_distinct = stats["n_distinct"].to_i if stats["n_distinct"]
      self.rowcount = rowcount

      if type < ActiveRecord::Type::Integer
        self.most_common_vals = self.most_common_vals.map(&:to_i) if self.most_common_vals
        self.histogram_bounds = self.histogram_bounds.map(&:to_i) if self.histogram_bounds
      end
    end

    def null_frac_high?
      return null_frac > THRESHOLD
    end

    def skewed_distribution?
      return most_common_freqs && (most_common_freqs.sum > THRESHOLD)
    end

    #
    def selectivity(op, val)
      if op == '='
        eq_selectivity(val)
      elsif op == '>'
        raise "NYI #{op}"
      elsif op == '<'
        raise "NYI #{op}"
      else
        raise "Unknown operator #{op}"
      end
    end

    def eq_selectivity(val)
      if (!most_common_vals.nil? && ind = most_common_vals.index(val))
        return most_common_freqs[ind]
      end
      return 1.0 / n_distinct if n_distinct && n_distinct > 0
      return 1.0 / rowcount if n_distinct && n_distinct < 0
    end
  end
end