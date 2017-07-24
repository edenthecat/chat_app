class AddUsersToConversations < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :user_1_id, :integer
    add_column :conversations, :user_2_id, :integer
  end
end
