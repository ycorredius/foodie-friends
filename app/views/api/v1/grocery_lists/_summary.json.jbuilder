# Expects counts: item counts by [grocery_list_id, status].
json.extract! grocery_list, :id, :name, :start_date, :end_date, :created_at
json.items_count GroceryListItem.statuses.keys.sum { |status| counts.fetch([grocery_list.id, status], 0) }
json.to_buy_count counts.fetch([grocery_list.id, "to_buy"], 0)
