class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :steps, array: true, null: false, default: []
      t.integer :servings, null: false
      t.integer :prep_minutes
      t.integer :cook_minutes
      t.integer :meal_type
      t.integer :difficulty
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end
    add_index :recipes, [:visibility, :id]
  end
end
