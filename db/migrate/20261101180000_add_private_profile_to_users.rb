class AddPrivateProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :private_profile, :boolean, null: false, default: false
  end
end
