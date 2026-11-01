# Expects @saved_recipe_ids: ids of the rendered recipes the current user saved.
json.extract! recipe, :id, :title, :description, :servings, :prep_minutes, :cook_minutes, :total_minutes,
  :meal_type, :difficulty, :tags, :visibility, :saves_count, :created_at, :updated_at
json.saved @saved_recipe_ids.include?(recipe.id)
# Recipes without a photo get the placeholder image, with default: true.
json.photo do
  if recipe.photo.attached?
    json.thumbnail_url rails_representation_url(recipe.photo.variant(:thumb))
    json.url rails_representation_url(recipe.photo.variant(:large))
    json.default false
  else
    json.thumbnail_url image_url("recipe_placeholder_thumb.png")
    json.url image_url("recipe_placeholder.png")
    json.default true
  end
end
json.author do
  json.partial! "api/v1/users/summary", user: recipe.user
end
