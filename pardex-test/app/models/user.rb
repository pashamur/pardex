require '/Users/pashamur/Desktop/Work/pardex/lib/pardex'

class User < ActiveRecord::Base

  def self.get_pardex
    self.class_eval { include Pardex }
  end
end
