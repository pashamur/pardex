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

~~~
Loaded suite pardex_spec
Started
Suggesting Indexes...

Suggested Index on test.read WHERE read = true (count: 2, selectivity: 0.0333)
Evaluating query SELECT * FROM test WHERE read = true
Suggested Index: test_read_idx_f09554029e WAS used. before: 0.473ms, after: 0.053ms.

Suggested Index on test.id WHERE id = 55 (count: 2, selectivity: 0.0001)
Evaluating query SELECT * FROM test WHERE id = 55
Suggested Index: test_id_idx_5ab532e9ea WAS used. before: 0.562ms, after: 0.007ms.

~~~


## Contributing

1. Fork it ( https://github.com/pashamur/pardex/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
