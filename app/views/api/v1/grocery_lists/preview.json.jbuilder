json.start_date @dates.first
json.end_date @dates.last
json.unavailable_meals_count @unavailable_meals_count
json.partial! "api/v1/grocery_lists/sections", items: @items, recipes_by_id: @recipes_by_id
