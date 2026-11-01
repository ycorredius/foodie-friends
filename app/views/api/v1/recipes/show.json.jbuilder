# Quantities are scaled to @servings and converted to the reader's unit system;
# `original` is the amount as the author wrote it.
factor = BigDecimal(@servings) / @recipe.servings

@saved_recipe_ids = Current.user.saved_recipes.where(recipe: @recipe).pluck(:recipe_id).to_set

json.partial! "api/v1/recipes/summary", recipe: @recipe
# The recipe this was copied from, if the reader can still see it.
source = @recipe.forked_from
if source && Recipe.visible_to(Current.user).exists?(source.id)
  json.forked_from do
    json.extract! source, :id, :title
    json.author do
      json.partial! "api/v1/users/summary", user: source.user
    end
  end
else
  json.forked_from nil
end
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
