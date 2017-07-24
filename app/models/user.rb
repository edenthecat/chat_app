class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :conversations
  has_many :sent_messages, :class_name => "Message", :foreign_key => "user_1_id"
  has_many :received_messages, :class_name => "Message", :foreign_key => "user_2_id", through: :conversations
end
