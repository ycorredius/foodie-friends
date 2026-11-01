json.extract! recipe, :id, :title, :description, :servings, :prep_minutes, :cook_minutes, :total_minutes,
  :meal_type, :difficulty, :tags, :visibility, :created_at, :updated_at
if recipe.photo.attached?
  json.photo do
    json.thumbnail_url rails_representation_url(recipe.photo.variant(:thumb))
    json.url rails_representation_url(recipe.photo.variant(:large))
  end
else
  json.photo nil
end
json.author do
  json.partial! "api/v1/users/summary", user: recipe.user
end
