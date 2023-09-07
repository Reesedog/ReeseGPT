json.extract! conversation, :id, :text, :created_at, :updated_at
json.url conversation_url(conversation, format: :json)
