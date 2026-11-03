json.extract! plan_template, :id, :name, :created_at
json.meals_count plan_template.meals.size
