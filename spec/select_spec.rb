require 'test/unit'
require_relative "../lib/pardex/aexpr_parser"
require_relative "../lib/pardex/pg_query_mods"

AEXPR_TEST = {
  "name" => ["="],
  "lexpr" => {"COLUMNREF" => {"fields" => ["users", "a"], "location" => 64 } },
  "rexpr" => {"A_CONST" => {"type" => "integer", "val" => 1, "location" => 74 } }, "location" => 72
}

class SelectTest < Test::Unit::TestCase
  SAMPLE_QUERY = "SELECT * FROM users WHERE a = 1 AND b = 2;"

  def test_aexpr
    @parser = Pardex::AExprParser.new(AEXPR_TEST)

    assert_equal(@parser.get_name, '=')
    assert_equal(@parser.get_var, 'users.a')
    assert_equal(@parser.get_val, 1)
  end

  def test_query
    query = PgQuery.parse(SAMPLE_QUERY)
    conds = query.useful_conditions

    assert_instance_of(Array, conds)
    assert_equal(conds[0], ["a", "=", 1])
    assert_equal(conds[1], ["b", "=", 2])
  end
end