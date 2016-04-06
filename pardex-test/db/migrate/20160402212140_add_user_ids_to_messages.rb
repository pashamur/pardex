class AddUserIdsToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :sender_id, :integer
    add_column :messages, :receiver_id, :integer
  end
end
