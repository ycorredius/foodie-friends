@saved_recipe_ids = Current.user.saved_recipes.where(recipe_id: @recipes.map(&:id)).pluck(:recipe_id).to_set

json.recipes @recipes, partial: "api/v1/recipes/summary", as: :recipe
json.next_page @next_page
