class AddUnitSystemToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :unit_system, :integer, null: false, default: 0
  end
end
