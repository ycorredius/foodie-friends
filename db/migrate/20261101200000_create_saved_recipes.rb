class CreateSavedRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end
    add_index :saved_recipes, [:user_id, :recipe_id], unique: true
    add_index :saved_recipes, [:recipe_id, :created_at]

    # Maintained by SavedRecipe's counter cache; used to sort by popularity.
    add_column :recipes, :saves_count, :integer, null: false, default: 0
  end
end
