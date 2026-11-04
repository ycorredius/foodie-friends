json.week_start @week.first
json.week_end @week.last
json.skipped_meals_count @skipped_meals_count unless @skipped_meals_count.nil?
json.planned_meals do
  json.partial! "api/v1/planned_meals/list", planned_meals: @planned_meals
end
