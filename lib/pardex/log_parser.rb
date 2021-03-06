require 'set'
require "pg_query"

# Taken (with modifications) from pghero_logs (github)
module Pardex
  class LogParser
    RAILS_4_REGEX = /duration: (\d+\.\d+) ms  execute <unnamed>: ([\s\S]+)?\Z/i
    RAILS_2_REGEX = /duration: (\d+\.\d+) ms  statement: ([\s\S]+)?\Z/i

    def parse(log_file, database_name)
      active_entry = ""
      log_file.each_line do |line|
        if line.include?(":  ")
          if active_entry
            parse_entry(active_entry, database_name)
          end
          active_entry = ""
        end
        if match = line.match(/(.*)--.*$/) # Remove single line comment
          line = match[1]
        end
        active_entry << line
      end
      parse_entry(active_entry, database_name)

      queries = self.queries.sort_by{|q, i| -i[:total_time] }
    end

    def parse_entry(active_entry, database_name)
      matches = active_entry.match(RAILS_4_REGEX)
      matches ||= active_entry.match(RAILS_2_REGEX)
      if matches && active_entry.include?("db=#{database_name}")
        # Filter out postgres / rails default queries
        return if active_entry =~ /pg_attribute|pg_type|schema_migrations|pg_class|pg_namespace/

        begin
          query = PgQuery.normalize(squish(matches[2].gsub(/\/\*.+/, ""))).gsub(/\?(, \?)+/, "?")
          queries[query][:count] += 1
          queries[query][:total_time] += matches[1].to_f
          queries[query][:samples] << squish(matches[2])
        rescue PgQuery::ParseError
          # do nothing
        end
      end
    end

    def print_statistics(queries)
      puts "Slowest Queries\n\n"
      puts "Total    Avg  Count  Query"
      puts "(min)   (ms)"
      queries.each do |query, info|
        puts "%5d  %5d  %5d  %s" % [info[:total_time] / 60000, info[:total_time] / info[:count], info[:count], query[0...60]]
      end

      puts "\nFull Queries\n\n"
      queries.each_with_index do |(query, info), i|
        puts "#{i + 1}."
        # To get unique queries that we care about: uniq{|k| PgQuery.parse(k).simple_where_conditions}
        info[:samples].each{|sample| puts "#{sample}\n"}
        puts ""
      end
    end

    def queries
      @queries ||= Hash.new {|hash, key| hash[key] = {count: 0, total_time: 0, samples: Array.new} }
    end

    def squish(str)
      str.gsub(/\A[[:space:]]+/, '').gsub(/[[:space:]]+\z/, '').gsub(/[[:space:]]+/, ' ')
    end
  end
end
