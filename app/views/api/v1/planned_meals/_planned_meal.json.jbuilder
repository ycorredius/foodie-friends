# Recipes the reader can no longer see render as null, with unavailable: true.
# Expects visible_ids (recipe ids the reader can see) and @saved_recipe_ids.
json.extract! meal, :id, :date, :meal_slot, :servings, :lock_version
json.unavailable !visible_ids.include?(meal.recipe_id)
if visible_ids.include?(meal.recipe_id)
  json.recipe do
    json.partial! "api/v1/recipes/summary", recipe: meal.recipe
  end
else
  json.recipe nil
end
