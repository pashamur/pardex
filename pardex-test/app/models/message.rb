require '/Users/pashamur/Desktop/Work/pardex/lib/pardex'

class Message < ActiveRecord::Base

  def self.get_pardex
    self.class_eval { include Pardex }
  end
end
