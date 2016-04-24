module Pardex
  class AExprParser
    attr_reader :val, :var

    def initialize(aexpr)
      @aexpr = aexpr
      hsh = @aexpr["lexpr"].merge(@aexpr["rexpr"])

      if hsh["A_CONST"] && hsh["COLUMNREF"]
        @val = hsh["A_CONST"]["val"]
        @var = hsh["COLUMNREF"]["fields"].join(".")
      else
        @val = @var = nil
      end
    end

    def get_condition
      return nil if @val.nil? || @val.nil?
      [get_var, get_name, get_val]
    end

    def get_name
      @aexpr["name"].first
    end

    def get_val
      @val
    end

    def get_var
      @var
    end
  end
end