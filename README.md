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
# app/models/user.rb
class User < ApplicationRecord
  # [...]
  has_many :conversations
  has_many :sent_messages, :class_name => "Message", :foreign_key => "user_1_id"
  has_many :received_messages, :class_name => "Message", :foreign_key => "user_2_id", through: :conversations
end
```

```
# app/models/conversation.rb
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
  # [...]
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
# /app/views/messages/create.js.erb
$("#newMessage input").val('');
```

All it needs to do is clear the input where we enter a new message, since the conversation will handle refreshing the page on a timed interval.

### Conversation

#### New

Since this demo app has a very minimal UI, we're going to simply allow a user to select who they want to chat with from the "new" form.

##### Controller Action

```
# /app/controllers/conversations_controller.rb
  def new
    @conversation = Conversation.new
    @conversation.user1 = current_user
  end
```

We initialize the current conversation, and we'll set the current user as user1 (the recipient will be user2).

##### View

The new view is fairly simple, it renders a _form partial for the conversation and has a back button that leads to the conversation index.

```
# /app/views/conversations/new.html.erb
<h1>New Conversation</h1>

<%= render 'form', conversation: @conversation %>

<%= link_to 'Back', conversations_path %>
```

The _form.html.erb partial should look like this:

```
# /app/views/conversations/_form.html.erb
<%= simple_form_for(@conversation) do |f| %>
  <%= f.error_notification %>

  <%= f.input :user2, collection: User.all.map{ |u| [u.email, u.id, { class: u.id}] } %>

  <div class="form-actions">
    <%= f.button :submit %>
  </div>
<% end %>
```

We'll let the user select a user to chat with simply by selecting their email. Right now, a user can chat with themselves. Later, we could set restrictions so that they can not do that (if we want to).

#### Create
```
# app/controllers/conversations_controller.rb
  def create
    @conversation = Conversation.new()

    @conversation.user1 = current_user
    @conversation.user2 = User.find(conversation_params[:user2].to_i)

    respond_to do |format|
      if @conversation.save
        format.html { redirect_to @conversation, notice: 'Conversation was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end
  ```

Our create action is fairly standard, but we need to make sure we set user1 and user2

#### Index

##### Controller Action

```
# app/controllers/conversations_controller.rb
  def index
    @conversations = Conversation.where("user_1_id = ? or user_2_id = ?", current_user.id, current_user.id)
  end
```

Here we want just the conversations that our current_user is a part of. We could use authorization later to do this a bit more simply.

##### View

```
# app/views/conversations/index.html.erb

<p id="notice"><%= notice %></p>

<h1>My Conversations</h1>

<table>
  <thead>
    <tr>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @conversations.each do |conversation| %>
      <tr>
        <td><%= link_to conversation do %>
            Conversation with <%= recipient(conversation).email %>
            <% end %>
        </td>
        <td><%= link_to conversation, method: :delete, data: { confirm: 'Are you sure?' } do %>
            <i class="fa fa-trash-o" aria-hidden="true"></i>
            <% end %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to 'New Conversation', new_conversation_path %>
```

Our view is fairly simple. It's just going to list out the email addresses (as links to the conversations), with the ability to destroy a conversation by clicking on a nice garbage can icon.

#### Show










