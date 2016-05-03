require 'test/unit'
require 'stringio'
require File.join(File.dirname(__FILE__), '../lib/pardex.rb')

class LogParserTest < Test::Unit::TestCase

  def test_log_parsing
    log = StringIO.new %q[2016-04-29 01:02:37 EDT [82306]: [16-1] user=pashamur,db=development_pasha LOG:  duration: 0.597 ms  statement: SELECT * FROM "user_tag_sets" WHERE ("user_tag_sets"."id" = 263162)
      2016-04-29 01:02:37 EDT [82306]: [17-1] user=pashamur,db=development_pasha LOG:  duration: 0.436 ms  statement: SELECT * FROM "guided_tours" WHERE ("guided_tours".user_account_id = 154212)]

    parser = Pardex::LogParser.new
    parser.parse(log, 'development_pasha')

    first_query = 'SELECT * FROM "user_tag_sets" WHERE ("user_tag_sets"."id" = 263162)'
    second_query = 'SELECT * FROM "guided_tours" WHERE ("guided_tours".user_account_id = 154212)'

    normalized_first_query = PgQuery.normalize(first_query)
    normalized_second_query = PgQuery.normalize(second_query)

    assert_equal(parser.queries[normalized_first_query][:count], 1)
    assert_equal(parser.queries[normalized_second_query][:count], 1)

    assert_equal(parser.queries[normalized_first_query][:total_time], 0.597)
    assert_equal(parser.queries[normalized_second_query][:total_time], 0.436)

    assert_equal(parser.queries[normalized_first_query][:samples].first, first_query)
    assert_equal(parser.queries[normalized_second_query][:samples].first, second_query)
  end


end