json.grocery_lists @grocery_lists, partial: "api/v1/grocery_lists/summary", as: :grocery_list, locals: {counts: @counts}
json.next_page @next_page
