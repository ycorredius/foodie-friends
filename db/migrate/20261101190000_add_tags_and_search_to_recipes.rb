class AddTagsAndSearchToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :tags, :string, array: true, null: false, default: []
    add_index :recipes, :tags, using: :gin

    # Copy of the recipe's ingredient names, kept in sync by Recipe so the
    # search column below can include them.
    add_column :recipes, :ingredient_names, :text, null: false, default: ""
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE recipes SET ingredient_names = COALESCE((
            SELECT string_agg(ingredients.name, ' ' ORDER BY recipe_ingredients.position)
            FROM recipe_ingredients JOIN ingredients ON ingredients.id = recipe_ingredients.ingredient_id
            WHERE recipe_ingredients.recipe_id = recipes.id
          ), '')
        SQL
      end
    end

    add_column :recipes, :searchable, :virtual, type: :tsvector, stored: true, as: <<~SQL.squish
      setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(description, '')), 'B') ||
      setweight(to_tsvector('english', coalesce(ingredient_names, '')), 'C')
    SQL
    add_index :recipes, :searchable, using: :gin
  end
end
