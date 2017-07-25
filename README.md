# Chat App Tutorial

## Getting Started

I used the rails devise template from Le Wagon for this tutorial, but if you have existing models and an app going already, you should be able to nest the Conversations model in whatever model it depends on.

## Our database

We already have a User model, and we'll need two new models: Conversation and Message.

A snapshot of our database will look something like this:

![alt text](http://i.imgur.com/aveYUkC.png "Database Schema")

We'll need to run some migrations to create the Conversation and Message models:

```
rails g migration CreateConversations
rails g migration AddUsersToConversation user_1_id:integer user_2_id:integer
rails g migration CreateMessages conversation:references user:references text:references
```

