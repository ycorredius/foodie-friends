class AddManualToGroceryListItems < ActiveRecord::Migration[8.1]
  def change
    # Items the household added by hand, rather than generated from the plan.
    # Regenerating a list will keep them.
    add_column :grocery_list_items, :manual, :boolean, null: false, default: false

    # One generated item per ingredient per list. A manual item can name an
    # ingredient the plan already needs ("milk" again); it stays its own line.
    remove_index :grocery_list_items, [:grocery_list_id, :ingredient_id], unique: true, where: "ingredient_id IS NOT NULL"
    add_index :grocery_list_items, [:grocery_list_id, :ingredient_id], unique: true, where: "ingredient_id IS NOT NULL AND NOT manual",
      name: "index_grocery_list_items_on_list_and_generated_ingredient"
  end
end
