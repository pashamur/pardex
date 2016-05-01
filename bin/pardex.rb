#!/usr/bin/env ruby

require_relative "../lib/pardex.rb"
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: pardex.rb [options]"

  opts.on("-l", "--log-file", "Specify location of postgres log file"){|v| options[:log_file] = v }
  opts.on("-d", "--db-name", "Specify database name"){|v| options[:db_name] = v }
  opts.on("-h", "--db-host", "Specify database host"){|v| options[:db_host] = v }
  opts.on("-p", "--db-port", "Specify database port"){|v| options[:db_port] = v.to_i }
  opts.on("-u", "--db-username", "Specify database username"){|v| options[:db_username] = v }
  opts.on("-P", "--db-password", "Specify database password"){|v| options[:db_password] = v }
end.parse!

defaults = {
  :log_file => "/usr/local/var/postgres/pg_log/ps_sample.log",
  :db_name => "development_pasha",
  :db_host => "localhost",
  :db_port => 5432,
  :db_username => "pashamur",
  :db_password => nil
}

Pardex.run(defaults.merge(options))
