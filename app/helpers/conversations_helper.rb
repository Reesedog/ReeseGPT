module ConversationsHelper
    def text_to_messages(text)
      messages = []
  
      text.split("\n").each do |line|
        role, content = line.split(": ", 2)
        messages << { "role" => role, "content" => content }
      end
  
      messages
    end
  end
  