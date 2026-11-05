class CreateGroceryLists < ActiveRecord::Migration[8.1]
  def change
    create_table :grocery_lists do |t|
      t.references :household, null: false, foreign_key: true
      t.string :name
      # The planned meals the list was generated from.
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    create_table :grocery_list_items do |t|
      t.references :grocery_list, null: false, foreign_key: {on_delete: :cascade}
      # Set on items generated from the plan; one item per ingredient per list.
      t.references :ingredient, foreign_key: true, index: false
      # Copied from the ingredient so the list is a snapshot.
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      # [{"quantity": "473.176473", "unit": "ml"}, ...] in grams, millilitres or
      # count units, converted to each reader's unit system when rendered.
      t.jsonb :amounts, null: false, default: []
      # Recipes that need the item; only those the reader can see are shown.
      t.bigint :recipe_ids, array: true, null: false, default: []
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :grocery_list_items, [:grocery_list_id, :ingredient_id], unique: true, where: "ingredient_id IS NOT NULL"
    add_index :grocery_list_items, :ingredient_id
  end
end
