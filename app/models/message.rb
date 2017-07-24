class Message < ApplicationRecord
  belongs_to :sender, :class_name => "User", :foreign_key => "user_id"
end
