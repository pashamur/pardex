require '/Users/pashamur/Desktop/Work/pardex/lib/pardex'

class User < ActiveRecord::Base
  has_many :sent_messages, :class_name => 'Message', :foreign_key => 'sender_id'
  has_many :received_messages, :class_name => 'Message', :foreign_key => 'receiver_id'

  def self.get_pardex
    self.class_eval { include Pardex }
  end
end
