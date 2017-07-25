# Chat App Tutorial

## Getting Started

I used the [rails devise template from Le Wagon](https://github.com/lewagon/rails-templates#devise) for this tutorial, but if you have existing models and an app going already, you should be able to nest the Conversations model in whatever model it depends on.

## Our database

We already have a User model, and we'll need two new models: Conversation and Message.

A snapshot of our database will look something like this:

![alt text](http://i.imgur.com/aveYUkC.png "Database Schema")

#### Migrations
We'll need to run some migrations to create the Conversation and Message models:

```
rails g migration CreateConversations
rails g migration AddUsersToConversation user_1_id:integer user_2_id:integer
rails g migration CreateMessages conversation:references user:references content:text
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

Here's where the AJAX comes in.

Initially our view will be fairly simple. Let's start by rendering the messages in the conversation.

##### View (Part 1)
```
# /app/views/conversations/show.html.erb
<div class="container" id="messages-list" >
  <% @conversation.messages.each do |message| %>
    <%= render "messages/show", message: message %>
  <% end %>
</div>
```

Notice that we use a partial in messages that will allow us to render each message individually. Let's take a look at that partial.

```
# /app/views/messages/_show.html.erb
<% if current_user.id == message.user_id then status = "sent" else status = "received" end %>

  <div class="message <%= status %>" data-message-id="<%= message.id %>">

  <p><%=  message.content %></p>

</div>
```

The partial checks to see who the message is coming from. If the message is sent by the user, it's given the class "sent", otherwise it's given the class "received". 

We also want to make sure that we store the message's ID so that we can grab it with jQuery later. This will help us when we're refreshing the messages.

Underneath our messages, we'll want a textbox where the user can send a new message. Let's use simple_form for that:

```
# /app/views/conversations/show.html.erb
<%= simple_form_for [@conversation, @message], :url => conversation_messages_path(@conversation), html: { id: "newMessage", class: "chat-form fixed bottom"}, method: "post", remote: true do |f| %>
    <%= f.text_field :content, id: "chat-field" %>
    <%= f.hidden_field :user_id, value: "current_user.id" %>
    <%= f.hidden_field :conversation_id, value: params[:conversation_id] %>
    <%= f.submit "Send", class: "btn btn-chat"%>
<% end %>
```
We need to specify the :url because the Message is a different model. We'll also give this form an id of newMessage (which we targetted in our messages/create.js.erb to clear the field). The simple form will trigger the message#create action, which will in turn respond with create.js.erb if it saves.

##### Controller Action

Comparatively, our show action is fairly simple. We just want to initialize the new message for the form:

```
# app/controllers/conversations_controller.rb
def show
    @message = Message.new
end
```

Keep in mind that we have a filter that sets the conversation :)

##### Refreshing Messages

We're going to need to do a few things to refresh the messages.

*Important:* First, make sure that you have a `yield(:after_js)` in our `application.html.erb`

###### JavaScript in Show

Our JavaScript in the show.html.erb will be comprised of three things: a function that refreshes the messages, an event listener that calls said function, and a function that will keep our #messages-list scrolled to the bottom (this will become particularly important once we add some styles.)

```
# app/views/conversations/show.html/erb
# [...]
<%= content_for(:after_js) do %>
  <script>
    $(document).ready(function() {
      scrollToBottom();
      setInterval(refreshMessages, 1000);
    });
    function scrollToBottom(){
      var d = $('#messages-list');
      d.scrollTop(d.prop("scrollHeight"));
    }
    function refreshMessages() {
      if($("#messages-list .message").length > 0) {
        var lastMessage = $("#messages-list .message").last().data("messageId");
        $.ajax({
          url: "<%= j refresh_messages_path(@conversation) %>",
          data: {last_message_id: lastMessage},
        });
      } else {
        $.ajax({
          url: "<%= j refresh_messages_path(@conversation) %>",
        });
      }
      scrollToBottom();
    }
  </script>
<% end %>
```
The `$(document).ready()` event listener calls the `scrollToBottom` function when the chat is first loaded. This means the user will see the most recent messages by default (without having to scroll). Then, we use `setInterval` to call `refreshMessages`.

`setInterval` is a function that requires us to pass it both a function, and a time interval in milliseconds. By saying `setInterval(refreshMessages, 1000);`, we'll be calling the `refreshMessages` function every 1 second. You can adjust the time as you see fit.

`refreshMessages` is where our AJAX happens. Remember when we set `data-message-id` in the `messages/_show` partial? We now use that data in order to determine what the last message rendered was, and we store it in `var lastMessage`. Note that when were dealing with `.data()` in jQuery we use camelCase rather than snake-case. If there are any messages, the `lastMessage` will be passed as the `last_message_id` to the refresh_messages_path.

Remember that when we wrote our routes, we wrote a custom route to a controller action `conversations#refresh_messages`. Now, we need to write that controller action. 

###### refresh_messages controller action and view

```
# app/controllers/conversations_controller.rb
  def refresh_messages
    if !params[:last_message_id].nil? &&
      last_message = @conversation.messages.find(params[:last_message_id])
      @messages = @conversation.messages.where("created_at > ?", last_message.created_at)
      respond_to do |format|
        format.js
      end
    end
  end
```

We want to check for that last_message_id, and if it isn't nil, we grab all messages that have been created since that last_message was rendered, and respond with js.

Rails will look for a `refresh_messages.js.erb` view to render because of that `respond_to` call.

```
# app/views/conversations/refresh_messages.js.erb
<% if !@messages.nil? %>
  <% @messages.each do |message| %>
    var msg_selector = $("#message_<%= message.id %>");
    $(msg_selector).remove();
    var msg = "<%= j render 'messages/show', message: message %>";
    $('#messages-list').append(msg);
  <% end %>
<% end %>
```

The `refresh_messages` view will check to make sure that we don't have an empty @messages, and then if there are @messages, will render a message partial for them and append them. I've also taken the time to check if the message already exists and remove it, just in case.

### Styling

I've done some basic styling, and placed it as a component in our stylesheets. It will simply render the received messages as blue, and the sent messages as grey. It will also place them on left/right based on if they were sent/received.

```
// app/assets/stylesheets/components/_messages.scss
#messages-list {
  display: flex;
  height: 60vh;
  width: 60%;
  overflow: scroll;
  flex-direction: column;
  scroll-behavior: smooth;
}

.message {
  padding: 10px;
  margin: 5px;
  &.received {
    align-self: flex-start;
    background-color: $blue;
    border-radius: 20px 20px 20px 0px;
    color: white;
  }
  &.sent {
    align-self: flex-end;
    background-color: #CECECE;
    border-radius: 20px 20px 0px 20px;
  }
}

form#newMessage {
    display: flex;
    justify-content: center;
}
```

Make sure to add @import "messages" to your component index!



----

And that's it! If you have any questions or confusion, please submit an issue or contact me (or submit a pull request ;)). 










