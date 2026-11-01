class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: {to_table: :users}
      t.references :followed, null: false, foreign_key: {to_table: :users}
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :follows, [:follower_id, :followed_id], unique: true
    add_index :follows, [:followed_id, :status]
    add_check_constraint :follows, "follower_id <> followed_id", name: "follows_not_self"
  end
end
