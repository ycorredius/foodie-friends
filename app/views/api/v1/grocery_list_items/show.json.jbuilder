json.partial! "api/v1/grocery_list_items/item", item: @item, recipes_by_id: @recipes_by_id
json.category @item.category
