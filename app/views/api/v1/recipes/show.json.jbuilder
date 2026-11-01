# Quantities are scaled to @servings and converted to the reader's unit system;
# `original` is the amount as the author wrote it.
factor = BigDecimal(@servings) / @recipe.servings

json.partial! "api/v1/recipes/summary", recipe: @recipe
json.servings @servings
json.recipe_servings @recipe.servings
json.steps @recipe.steps
json.ingredients @recipe.recipe_ingredients do |line|
  amount = line.amount_for(system: Current.user.unit_system, factor: factor)
  json.name line.name
  json.category line.category
  json.quantity amount.quantity&.to_f
  json.unit amount.unit
  json.note line.note
  json.original do
    json.quantity line.quantity&.to_f
    json.unit line.unit
  end
end
