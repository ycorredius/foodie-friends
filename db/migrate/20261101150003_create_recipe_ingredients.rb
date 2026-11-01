class CreateRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 3
      t.string :unit
      t.string :note
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
