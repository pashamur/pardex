# Pardex

A gem that analyzes Postgres query logs (for Rails applications) and finds commonly occuring conditions (for use in potential partial indexes). It can also test the indexes to see whether they improve performance, and whether postgres would actually use them in the logged queries.

It uses regexes to extract the queries from the postgres logs - for certain version of rails (or to use this gem with other systems), the regexes will have to be modified. They are found in lib/pardex/log_parser.rb.

## Usage

(If you already have log data, skip to step 3)

1. First, you have to enable logging in your postgres instance. You can follow the instructions under "Postgres Configuration" for pgBadger (reproduced here for convenience.)

    POSTGRESQL CONFIGURATION
    You must enable and set some configuration directives in your
    postgresql.conf before starting. (You can use a value greater than 0 for log_min_duration_statement to reduce logged query volume)
    ~~~
    log_statement = none
    log_min_duration_statement = 0
    log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '
    ~~~

2. Launch and browse around your application - the resulting queries will be logged in the postgres log.
3. Clone the https://github.com/pashamur/pg_query fork and install that pg_query on your system (gem build pg_query.gemspec, gem install pg_query-0.9.1.gem) (there's an additional method called simple_where_conditions, which is not present in the original gem)
4. Clone the repository and run ./bin/pardex, specifying the log file to be analyzed and the database host, port, username and password (the same one that your application uses when running). Output should appear on the command line. Usage below:


~~~
Usage: pardex [options]
-l, --log-file=NAME              Specify location of postgres log file
-d, --db-name=NAME               Specify database name
-h, --db-host=NAME               Specify database host
-p, --db-port=NAME               Specify database port
-u, --db-username=NAME           Specify database username
-P, --db-password=NAME           Specify database password
-c, --min-count=NAME             Minimum number of queries for a condition to be considered for a partial index (default: 2)
-e, --evaluate                   Whether to run index evaluation on each resulting index
-f, --filter-id                  Filter out suggestions on likely id columns (matching _id or .id or ^id$)
~~~

##Sample output:
Generated from running the spec in spec/pardex_spec (needs postgres to be installed and password-less access for current user on localhost on default port)

The test uses a log with the following seven queries (with a count of 2, so it considers any query occuring >= 2 times for a partial index): 
~~~
SELECT * FROM test WHERE id = 55
SELECT * FROM test WHERE id = 55
SELECT * FROM test WHERE read = true
SELECT * FROM test WHERE read = true
SELECT * FROM test WHERE read = false
SELECT * FROM test WHERE read = false
SELECT * FROM test WHERE id = 68
~~~

### OUTPUT: 

The evaluation statistics (USED, BEFORE, AFTER, SPEEDUP) are only reported if --evaluate is passed into the binary. Currently, evaluations are done on the query `SELECT * FROM #{index_table} WHERE #{partial index condition}`.
    - USED represents whether the partial index was used when evaluating the above query
    - BEFORE represents the average query runtime WITHOUT the partial index (in ms)
    - AFTER represents the average query runtime WITH the partial index (in ms)
    - SPEEDUP represents the speedup (hence a value of 10 would represent 10x speedup for the above query). Values less than one actually hurt the runtime of the query.

~~~
Loaded suite pardex_spec
Started
Suggesting Indexes...

Suggested Index on test.read WHERE read = true (count: 2, selectivity: 0.033)
Suggested Index on test.id WHERE id = 55 (count: 2, selectivity: 0.0)

TABLE | ATTRIBUTE | OP | VALUE | COUNT | SELECTIVITY | USED | BEFORE | AFTER | SPEEDUP
------|-----------|----|-------|-------|-------------|------|--------|-------|--------
test  | id        | =  | 55    | 2     | 0.0001      | Y    | 0.712  | 0.007 | 101.714
test  | read      | =  | true  | 2     | 0.0333      | Y    | 0.581  | 0.054 | 10.759
~~~


## Contributing

1. Fork it ( https://github.com/pashamur/pardex/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
