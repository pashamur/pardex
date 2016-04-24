require 'pg'
require 'pg_query'

QUERIES = [
  "SELECT count(*) FROM users",
  "SELECT count(*) FROM users WHERE first_name = 'Roger'",
  "SELECT count(*) FROM messages WHERE read IS TRUE",
  "SELECT count(*) FROM messages WHERE read IS TRUE",
  "SELECT count(*) FROM messages WHERE read = 't'",
].freeze

class SelectTest < Test::Unit::TestCase



end