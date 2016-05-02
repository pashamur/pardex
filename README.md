# Pardex

A gem that analyzes Postgres query logs (for Rails applications) and finds commonly occuring conditions (for use in potential partial indexes). It can also test the indexes to see whether they improve performance, and whether postgres would actually use them in the logged queries.

It uses regexes to extract the queries from the postgres logs - for certain version of rails (or to use this gem with other systems), the regexes will have to be modified. They are found in lib/pardex/log_parser.rb.

## Usage

(If you already have log data, skip to step 3)

1. First, you have to enable logging in your postgres instance. You can follow the instructions under "Postgres Configuration" for pgBadger (reproduced here for convenience.)

POSTGRESQL CONFIGURATION
    You must enable and set some configuration directives in your
    postgresql.conf before starting.

    log_statement = none
    log_min_duration_statement = 0

    Here every statement will be logged, on a busy server you may want to
    increase this value to only log queries with a longer duration. 

    log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '

2. Launch and browse around your application - the resulting queries will be logged in the postgres log.
3. Run pardex, specifying the log file to be analyzed and the database host, port, username and password (the same one that your application uses when running). Output should appear on the command line.

Sample output:
~~~
Suggesting Indexes...

Suggested Index on user_accounts.id WHERE user_accounts.id = 154212 (selectivity: 4.238042363471465e-06)
Evaluating query SELECT "user_accounts".id FROM "user_accounts" INNER JOIN "subscriptions_owner_user_accounts" ON "user_accounts".id = "subscriptions_owner_user_accounts".user_account_id WHERE ("user_accounts"."id" = 154212) AND ("subscriptions_owner_user_accounts".subscription_id = 9899 ) LIMIT 1
Suggested Index: user_accounts_id_idx_476ae0f44f WAS used. before: 0.014ms, after: 0.013ms.

Suggested Index on saved_profiles.user_account_id WHERE saved_profiles.user_account_id = 154212 (selectivity: 4.640801930573603e-05)
Evaluating query SELECT count(*) AS count_all FROM "saved_profiles" WHERE (("saved_profiles"."user_account_id" = 154212 AND "saved_profiles"."stype" = 'saved' AND "saved_profiles"."watched" = 't'))
Suggested Index: saved_profiles_user_account_id_idx_cfbfe7b576 WAS NOT used. before: 0.016ms, after: 0.019ms.
~~~

Clone the repo; the binary is in bin/pardex.

~~~
Usage: pardex [options]
    -l, --log-file=NAME              Specify location of postgres log file
    -d, --db-name=NAME               Specify database name
    -h, --db-host=NAME               Specify database host
    -p, --db-port=NAME               Specify database port
    -u, --db-username=NAME           Specify database username
    -P, --db-password=NAME           Specify database password
~~~


## Contributing

1. Fork it ( https://github.com/[my-github-username]/pardex/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
