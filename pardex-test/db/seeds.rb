# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

USER_COUNT    = 100_000.freeze
MESSAGE_COUNT = 10_000_000.freeze
PERCENT_READ  = 98.freeze

# users = []
# USER_COUNT.times do |index|
#   puts "#{index} Users Loaded" if index % (USER_COUNT / 10) == 0

#   users << {
#     :first_name => Faker::Name.first_name,
#     :last_name => Faker::Name.last_name,
#     :email => Faker::Internet.email,
#     :password => Faker::Internet.password,
#   }
# end

# puts "Creating Users..."
# User.create(users)
# puts "#{USER_COUNT} Users Created"

messages = []

date = DateTime.now.to_s

MESSAGE_COUNT.times do |index|
  messages << "(#{(rand * USER_COUNT).to_i}, #{(rand * USER_COUNT).to_i}, 'Moo ha ha', '#{rand > (PERCENT_READ * 0.01) ? 't' : 'f'}', '#{date}', '#{date}')"

  if index % 50_000 == 0
    sql = "INSERT INTO messages (sender_id, receiver_id, message, read, created_at, updated_at) VALUES #{messages.join(', ')}"
    Message.connection.execute(sql)
    puts "Messages: #{(100 * index.to_f / MESSAGE_COUNT).round(1)}% Created"
    messages = []
  end
end
