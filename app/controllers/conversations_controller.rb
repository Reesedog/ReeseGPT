require 'net/http'

class ConversationsController < ApplicationController
  before_action :set_conversation, only: %i[ show edit update destroy ]

  def index
    @conversations = Conversation.all
  end

  def show
  end

  def new
    @conversation = current_user.conversations.build
  end

  def edit
  end

  

  def create
    formatted_input = { role: "user", content: conversation_params[:text] }
    @conversation = current_user.conversations.build(text: [formatted_input])
  
    gpt_response = get_gpt_response(@conversation.text)
  
    @conversation.text << { role: "assistant", content: gpt_response }
    respond_to do |format|
      if @conversation.save
        format.html { redirect_to conversation_url(@conversation), notice: "Conversation was successfully created." }
        format.json { render :show, status: :created, location: @conversation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @conversation.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    user_input = { role: "user", content: params[:new_text] }
    @conversation.text << user_input
  
    gpt_response = get_gpt_response(@conversation.text)
  
    @conversation.text << { role: "assistant", content: gpt_response }
    
    respond_to do |format|
      if @conversation.save
        format.html { redirect_to edit_conversation_url(@conversation), notice: "Message was successfully sent." }
        format.json { render :show, status: :ok, location: @conversation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @conversation.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @conversation.destroy

    respond_to do |format|
      format.html { redirect_to conversations_url, notice: "Conversation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:text)
  end

  def text_to_messages(text)
    messages = []

    text.split("\n").each do |line|
      role, content = line.split(": ", 2)
      messages << { "role" => role, "content" => content }
    end

    messages
  end

  def get_gpt_response(messages)
    uri = URI("https://api.openai.com/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer "
    request["Content-Type"] = "application/json"
  
    request.body = JSON.dump({
      "model" => "gpt-4",
      "messages" => messages.map { |msg| msg.transform_keys(&:to_s) },
      "temperature" => 0.7,
    })
  
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  
    json_response = JSON.parse(response.body)
    suggested_plan = json_response["choices"][0]["message"]["content"]
  
    return suggested_plan
  end
end
