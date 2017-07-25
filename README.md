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

## Routes

```
Rails.application.routes.draw do
  [...]
  resources :conversations do
    resources :messages, only: [:index, :new, :create, :destroy]
  end

  get '/conversations/:id/refresh_messages', to: 'conversations#refresh_messages', as: 'refresh_messages'
  devise_for :users
  root to: 'conversations#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
```

Messages are nested in conversations, since they belong_to a Conversation.

We have a custom route for a method refresh_messages which will handle our AJAX request to get the new messages.

## Controllers & Views

### Messages

#### Filters
Be sure to add a set_message filter that you can reuse throughout the controller.

```
  def set_message
    @message = Message.find(params[:id])
  end
```

We're also going to need the conversation so let's add a filter for that.

```
    def set_conversation
      @conversation = Conversation.find(params[:conversation_id])
    end
```

At the top of our controller, be sure to call the filters.

```
  before_action :set_message, only: [:show, :edit, :update, :destroy]
  before_action :set_conversation, only: [:new, :create]
```

#### New

##### Controller Action
```
  def new
    @message = Message.new
  end
```

We will not need a view for this action as we'll be creating new messages from the conversation show view.

#### Create

##### Controller Action
```
  def create
    @message = Message.new(message_params)
    @message.user_id = current_user.id
    @message.conversation_id = @conversation.id

    if @message.save!
      respond_to do |format|
        format.js
      end
    end
  end
```

The controller will exclusively respond with javascript (it will be looking for a `create.js.erb` file).

##### View

We use a js.erb view to do one simple thing:

```
$("#newMessage input").val('');
```

All it needs to do is clear the input where we enter a new message, since the conversation will handle refreshing the page on a timed interval.






