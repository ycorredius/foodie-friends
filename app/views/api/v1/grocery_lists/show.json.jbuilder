json.extract! @grocery_list, :id, :name, :start_date, :end_date, :created_at
json.unavailable_meals_count @unavailable_meals_count unless @unavailable_meals_count.nil?
json.partial! "api/v1/grocery_lists/sections", items: @items, recipes_by_id: @recipes_by_id
