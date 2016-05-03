require 'rubygems'
require 'test/unit'
require 'pg'
require 'stringio'
require 'tempfile'
require File.join(File.dirname(__FILE__), '../lib/pardex.rb')

class PardexTest < Test::Unit::TestCase
  LOG_PREFIX = "2016-04-29 01:02:37 EDT [82306]: [16-1] user=pashamur,db=pardex_spec LOG:  duration: 0.1 ms  statement: "
  CREATE_TABLE_QUERY = %{
    CREATE TABLE test AS (SELECT generate_series(1,10000) AS id, false as read, 'This is a message'::text as message)
  }
  UPDATE_TABLE_QUERY = "UPDATE test SET read = true WHERE id % 30 = 0"
  ANALYZE_QUERY = "ANALYZE test"

  LOG = %Q[
#{LOG_PREFIX} SELECT * FROM test WHERE id = 55
#{LOG_PREFIX} SELECT * FROM test WHERE id = 55
#{LOG_PREFIX} SELECT * FROM test WHERE read = true
#{LOG_PREFIX} SELECT * FROM test WHERE read = true
#{LOG_PREFIX} SELECT * FROM test WHERE read = false
#{LOG_PREFIX} SELECT * FROM test WHERE read = false
#{LOG_PREFIX} SELECT * FROM test WHERE id = 67
]

  def setup
    conn = PG::Connection.open(:dbname => 'postgres')
    conn.exec("CREATE DATABASE pardex_spec")
    conn.close

    @connection = PG::Connection.open(:dbname => 'pardex_spec')
    @connection.exec(CREATE_TABLE_QUERY)
    @connection.exec(UPDATE_TABLE_QUERY)
    @connection.exec(ANALYZE_QUERY)

    @file = Tempfile.new('foo')
    @file.write(LOG)
    @file.close
  end

  def test_pardex
    begin
      indexes = Pardex.run(:db_name => 'pardex_spec', :log_file => @file.path)
      assert_equal([['id', '=', 55], ['read', '=', true]].to_set, indexes.to_set)
    ensure
      @connection.close if @connection
      @file.unlink if @file
      conn = PG::Connection.open(:dbname => 'postgres')
      conn.exec("DROP DATABASE pardex_spec")
      conn.close
    end
  end
end