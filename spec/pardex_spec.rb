require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/associations'
require File.join(File.dirname(__FILE__), '../lib/pardex.rb')

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :posts do |t|
      t.column :name, :string
    end

    create_table :comments do |t|
      t.column :name, :string
      t.column :post_id, :string
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Post < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

class BulletTest < Test::Unit::TestCase
  def setup
    teardown
    setup_db

    Post.class_eval{ include Pardex; }
    post = Post.create(:name => 'first')
    Comment.create(:name => 'first', :post => post)
    Comment.create(:name => 'second', :post => post)
    post = Post.create(:name => 'second')
    Comment.create(:name => 'third', :post => post)
    Comment.create(:name => 'fourth', :post => post)
  end

  def teardown
    teardown_db
  end

  def test_one
    setup
    Post.includes(:comments).all.each do |post|
      post.comments
    end
    teardown
  end

  def test_two
    setup
    Post.all.each do |post|
      post.comments
    end
    teardown
  end

end