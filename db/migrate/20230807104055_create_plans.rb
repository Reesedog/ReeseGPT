class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.integer :user_id
      t.string :name
      t.string :disability
      t.string :support
      t.string :goal
      t.string :plan

      t.timestamps
    end
  end
end
