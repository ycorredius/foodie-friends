# Expects recipes_by_id (the recipes the reader can see, by id). Unsaved items
# (previews) have no id or status.
if item.persisted?
  json.id item.id
  json.status item.status
end
json.ingredient_id item.ingredient_id
json.name item.name
json.amounts item.amounts do |amount|
  amount = Unit.display(amount, system: Current.user.unit_system)
  json.quantity amount.quantity.to_f
  json.unit amount.unit
end
json.recipes item.recipe_ids.filter_map { |id| recipes_by_id[id] } do |recipe|
  json.extract! recipe, :id, :title
end
