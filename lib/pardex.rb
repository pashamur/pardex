require_relative "pardex/version"
require_relative "pardex/table"
require 'active_record'
require 'byebug'

module Pardex
  def self.included(klass)
    raise "Need ActiveRecord class but got #{klass}" unless klass <= ActiveRecord::Base

    table = Pardex::Table.new(klass)
    byebug
  end
end
