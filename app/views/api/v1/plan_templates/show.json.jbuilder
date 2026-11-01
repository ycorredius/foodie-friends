# Recipes the reader can no longer see render as null, with unavailable: true.
recipe_ids = @plan_template.meals.map(&:recipe_id)
visible_ids = Recipe.visible_to(Current.user).where(id: recipe_ids).pluck(:id).to_set
@saved_recipe_ids = Current.user.saved_recipes.where(recipe_id: recipe_ids).pluck(:recipe_id).to_set

json.partial! "api/v1/plan_templates/summary", plan_template: @plan_template
json.meals @plan_template.meals do |meal|
  json.extract! meal, :id, :weekday, :meal_slot, :servings
  json.unavailable !visible_ids.include?(meal.recipe_id)
  if visible_ids.include?(meal.recipe_id)
    json.recipe do
      json.partial! "api/v1/recipes/summary", recipe: meal.recipe
    end
  else
    json.recipe nil
  end
end
