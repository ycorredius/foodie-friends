json.start_date @grocery_list.dates.first
json.end_date @grocery_list.dates.last
json.unavailable_meals_count @grocery_list.unavailable_meals_count
json.sections @grocery_list.sections do |section|
  json.category section.category
  json.items section.items do |item|
    json.ingredient_id item.ingredient.id
    json.name item.ingredient.name
    json.amounts item.amounts do |amount|
      json.quantity amount.quantity.to_f
      json.unit amount.unit
    end
    json.recipes item.recipes do |recipe|
      json.extract! recipe, :id, :title
    end
  end
end
