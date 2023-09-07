class ChangeTextToJsonInConversations < ActiveRecord::Migration[7.0]
  def change
    change_column :conversations, :text, :jsonb, default: []
  end
end
