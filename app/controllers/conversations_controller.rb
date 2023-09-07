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

  

  # POST /conversations or /conversations.json
  def create
    formatted_input = "user: #{conversation_params[:text]}"
    @conversation = current_user.conversations.build(text: formatted_input)

    gpt_response = get_gpt_response(formatted_input)

    @conversation.text += "\nassistant: #{gpt_response}"
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
    user_input = params[:new_text]
    formatted_input = "user: #{user_input}"
    @conversation.text += "\n#{formatted_input}"

    gpt_response = get_gpt_response(@conversation.text)

    @conversation.text += "\nassistant: #{gpt_response}"
  
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

  def get_gpt_response(user_input)
    uri = URI("https://api.openai.com/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = 
    request["Content-Type"] = "application/json"

    messages = text_to_messages(user_input)

    request.body = JSON.dump({
      "model" => "gpt-4",
      "messages" => messages,
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
