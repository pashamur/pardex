EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) SELECT * FROM messages_part WHERE read='t' LIMIT 1000;
