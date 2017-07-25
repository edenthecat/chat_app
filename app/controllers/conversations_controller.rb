class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :refresh_messages]
  helper_method :recipient

  # GET /conversations
  # GET /conversations.json
  def index
    raise
    @conversations = Conversation.where("user_1_id = ? or user_2_id = ?", current_user.id, current_user.id)
  end

  # GET /conversations/1
  # GET /conversations/1.json
  def show
    @message = Message.new
  end

  # GET /conversations/new
  def new
    @conversation = Conversation.new
    @conversation.user1 = current_user
  end

  # POST /conversations
  # POST /conversations.json
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

  # PATCH/PUT /conversations/1
  # PATCH/PUT /conversations/1.json
  def update
    respond_to do |format|
      if @conversation.update(conversation_params)
        format.html { redirect_to @conversation, notice: 'Conversation was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /conversations/1
  # DELETE /conversations/1.json
  def destroy
    @conversation.destroy
    respond_to do |format|
      format.html { redirect_to conversations_url, notice: 'Conversation was successfully destroyed.' }
    end
  end

  def refresh_messages
    if !params[:last_message_id].nil? &&
      last_message = @conversation.messages.find(params[:last_message_id])
      @messages = @conversation.messages.where("created_at > ?", last_message.created_at)
      respond_to do |format|
        format.js
      end
    end
  end

  def recipient(conversation)
    recipient = current_user == conversation.user1 ? conversation.user2 : conversation.user1
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conversation
      @conversation = Conversation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def conversation_params
      params.require(:conversation).permit(:user2)
    end
end
