json.extract! recipe, :id, :title, :description, :servings, :prep_minutes, :cook_minutes, :total_minutes,
  :meal_type, :difficulty, :visibility, :created_at, :updated_at
json.author do
  json.partial! "api/v1/users/author", user: recipe.user
end
