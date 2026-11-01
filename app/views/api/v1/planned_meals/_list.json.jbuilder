recipe_ids = planned_meals.map(&:recipe_id)
visible_ids = Recipe.visible_to(Current.user).where(id: recipe_ids).pluck(:id).to_set
@saved_recipe_ids = Current.user.saved_recipes.where(recipe_id: recipe_ids).pluck(:recipe_id).to_set

json.array! planned_meals, partial: "api/v1/planned_meals/planned_meal", as: :meal, locals: {visible_ids: visible_ids}
