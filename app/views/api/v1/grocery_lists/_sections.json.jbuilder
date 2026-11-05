# Expects items and recipes_by_id (the recipes the reader can see, by id).
json.sections GroceryListItem.sections(items) do |category, section_items|
  json.category category
  json.items section_items, partial: "api/v1/grocery_list_items/item", as: :item, locals: {recipes_by_id: recipes_by_id}
end
