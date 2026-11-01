visible_ids = Recipe.visible_to(Current.user).where(id: @planned_meal.recipe_id).pluck(:id).to_set
@saved_recipe_ids = Current.user.saved_recipes.where(recipe_id: @planned_meal.recipe_id).pluck(:recipe_id).to_set

json.partial! "api/v1/planned_meals/planned_meal", meal: @planned_meal, visible_ids: visible_ids
