json.recipes @recipes, partial: "api/v1/recipes/summary", as: :recipe
json.next_page @pagy.next
