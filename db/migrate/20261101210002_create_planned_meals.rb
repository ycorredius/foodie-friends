class CreatePlannedMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :planned_meals do |t|
      t.references :household, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: {on_delete: :cascade}
      t.date :date, null: false
      t.integer :meal_slot, null: false
      t.integer :servings, null: false

      t.timestamps
    end
    add_index :planned_meals, [:household_id, :date]
  end
end
