# A week of the household's planned meals. `:date` is any date (YYYY-MM-DD) in
# the week; weeks start on the user's week_start_day.
class Api::V1::MealPlansController < Api::V1::BaseController
  before_action :set_week

  def show
    render_week
  end

  # Copies the meals from the week containing `from` (default: the previous
  # week) onto the same weekdays of this week. Refuses with 409 if this week
  # already has meals, unless `replace` is true. Recipes the user can no longer
  # see aren't copied.
  def copy
    source = params[:from].present? ? week_for(params[:from]) : (@week.first - 7.days)..(@week.last - 7.days)
    return if performed?
    if source == @week
      return render json: {errors: {from: ["must be a different week"]}}, status: :unprocessable_entity
    end

    offset = @week.first - source.first
    replace_week do
      household.planned_meals.where(date: source, recipe_id: Recipe.visible_to(Current.user).select(:id)).find_each do |meal|
        household.planned_meals.create!(recipe_id: meal.recipe_id, meal_slot: meal.meal_slot, servings: meal.servings,
          date: meal.date + offset)
      end
    end
  end

  # Fills this week from the household's template `plan_template_id`, putting
  # each meal on the day with its weekday. Same 409/`replace` rule as copy.
  # Recipes the user can no longer see are left out and counted in
  # `skipped_meals_count`; if none are left, nothing changes and it's a 422.
  def apply_template
    template = household.plan_templates.find(params.expect(:plan_template_id))
    meals = template.meals.where(recipe_id: Recipe.visible_to(Current.user).select(:id)).to_a
    if meals.empty?
      return render json: {errors: {plan_template_id: ["has no recipes you can still see"]}}, status: :unprocessable_entity
    end

    @skipped_meals_count = template.meals.size - meals.size
    dates_by_wday = @week.index_by(&:wday)
    replace_week do
      meals.each do |meal|
        household.planned_meals.create!(recipe_id: meal.recipe_id, meal_slot: meal.meal_slot, servings: meal.servings,
          date: dates_by_wday.fetch(meal.wday))
      end
    end
  end

  private

  # Clears this week and runs the block in one transaction, then renders the
  # week. Renders a 409 instead if the week already has meals and `replace`
  # isn't true.
  def replace_week
    existing = household.planned_meals.where(date: @week)
    if existing.exists? && !ActiveModel::Type::Boolean.new.cast(params[:replace])
      return render json: {
        error: "This week already has planned meals. Send replace: true to replace them.",
        planned_meals_count: existing.count
      }, status: :conflict
    end

    PlannedMeal.transaction do
      existing.delete_all
      yield
    end
    render_week
  end

  def household
    Current.user.household
  end

  def set_week
    @week = week_for(params[:date])
  end

  def render_week
    @planned_meals = household.planned_meals.between(@week).includes(recipe: [:user, {photo_attachment: :blob}])
    render :show
  end
end
