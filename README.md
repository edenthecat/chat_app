# Chat App Tutorial

## Getting Started

I used the rails devise template from Le Wagon for this tutorial, but if you have existing models and an app going already, you should be able to nest the Conversations model in whatever model it depends on.

## Our database

We already have a User model, and we'll need two new models: Conversation and Message.

A snapshot of our database will look something like this:

![alt text](http://i.imgur.com/aveYUkC.png "Database Schema")

#### Migrations
We'll need to run some migrations to create the Conversation and Message models:

```
rails g migration CreateConversations
rails g migration AddUsersToConversation user_1_id:integer user_2_id:integer
rails g migration CreateMessages conversation:references user:references text:references
```

#### Associations & Validations

We'll also have to add some associations

```
app/models/user.rb
class User < ApplicationRecord
  [...]
  has_many :conversations
  has_many :sent_messages, :class_name => "Message", :foreign_key => "user_1_id"
  has_many :received_messages, :class_name => "Message", :foreign_key => "user_2_id", through: :conversations
end
```

```
app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :user1, :class_name => "User", :foreign_key => "user_1_id"
  belongs_to :user2, :class_name => "User", :foreign_key => "user_2_id"
  has_many :messages
end
```

```
class Message < ApplicationRecord
  belongs_to :sender, :class_name => "User", :foreign_key => "user_id"
end
```

You can add validations as you please.


