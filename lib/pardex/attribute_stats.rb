module Pardex
  class AttributeStats
    THRESHOLD = 0.95
    attr_accessor :name, :null_frac, :most_common_vals, :most_common_freqs, :histogram_bounds, :n_distinct, :rowcount, :table, :type

    def initialize(name, stats, rowcount, type, table)
      self.name = name
      self.type = type
      self.table = table
      self.null_frac = stats['null_frac'].to_f
      self.most_common_vals = stats["most_common_vals"].gsub(/[{}]/,'').split(',') if stats["most_common_vals"]
      self.most_common_freqs = stats["most_common_freqs"].gsub(/[{}]/,'').split(',').map(&:to_f) if stats["most_common_freqs"]
      self.histogram_bounds = stats["histogram_bounds"].gsub(/[{}]/,'').split(',') if stats["histogram_bounds"]
      self.n_distinct = stats["n_distinct"].to_i if stats["n_distinct"]
      self.rowcount = rowcount

      if type == "integer"
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
      if op == "IS" && val == "NULL"
        return self.null_frac
      elsif op == "IS" && [true, false].include?(val)
        val ? eq_selectivity('t') : eq_selectivity('f')
      elsif op == "IS NOT" && val == "NULL"
        return 1.0 - self.null_frac
      elsif op == "IS NOT" && [true, false].include?(val)
        bool_val = (val ? 'f' : 't')
        eq_selectivity(bool_val) + self.null_frac
      elsif op == '='
        eq_selectivity(val)
      elsif op == '>'
        !(histogram_bounds.nil?) ? gt_selectivity(val) : get_selectivity_from_postgres(op, val)
      elsif op == '<'
        !(histogram_bounds.nil?) ? lt_selectivity(val) : get_selectivity_from_postgres(op, val)
      elsif op == '<=' || op == '>='
        if histogram_bounds.nil?
          get_selectivity_from_postgres(op, val)
        else
          eq_selectivity(val) + (op == '<=' ? lt_selectivity(val) : gt_selectivity(val))
        end
      else
        get_selectivity_from_postgres(op, val)
      end
    end

    def get_selectivity_from_postgres(op, val)
      # Hijack postgres planner to give us estimate
      begin
        esc_val = val.is_a?(String) && !(['true','false','null'].include?(val.downcase)) && op != "IN" ? "'#{val}'" : val
        res = self.table.connection.execute("EXPLAIN (FORMAT JSON) SELECT * FROM #{self.table.name} WHERE #{self.table.name}.#{name} #{op} #{esc_val};")

        plan_rows = JSON.parse(res.first["QUERY PLAN"]).first["Plan"]["Plan Rows"]
        plan_rows.to_f / rowcount
      rescue => e
        puts "ERROR: Failed to compute selectivity for #{name} #{op} #{val} (table = #{table.name}); Defaulting to 0."
        puts e.inspect
        0
      end
    end

    def eq_selectivity(val)
      # Check for boolean queries with 1 or 0
      if most_common_vals.is_a?(Array)
        if self.type=='boolean' && ['1', '0', true, false].include?(val)
          t_val = most_common_vals.index('t')
          f_val = most_common_vals.index('f')
          return ((val == '1' || val == true) ? most_common_freqs[t_val] : most_common_freqs[f_val])
        end

        if ind = most_common_vals.index(val)
          return most_common_freqs[ind]
        end

        return 0 if n_distinct == most_common_vals.length # Not in most common vals; not present
      end

      return 1.0 / n_distinct if n_distinct && n_distinct > 0
      return 1.0 / rowcount if n_distinct && n_distinct < 0
      return get_selectivity_from_postgres('=', val)
    end

    def gt_selectivity(val)
      return 0 if val > histogram_bounds.last
      return 1 if val < histogram_bounds.first

      1.0 - lt_selectivity(val) - eq_selectivity(val)
    end

    def lt_selectivity(val)
      return 0 if val < histogram_bounds.first
      return 1 if val > histogram_bounds.last

      full = histogram_bounds.select{|b| b < val}.count
      low, high = [histogram_bounds.reverse.find{|x| x < val}, histogram_bounds.find{|x| x > val}]
      partial = val.is_a?(Numeric) ? (val - low).to_f / (high - low) : 0

      histogram_selectivity = (full + partial).to_f / histogram_bounds.count
      # Get select
      common_selectivity = if most_common_vals
        most_common_vals.zip(most_common_freqs).reduce(0){|tot, (v, freq)| v > val ? tot + freq : tot}
      else
        0
      end

      histogram_selectivity + common_selectivity
    end
  end
end