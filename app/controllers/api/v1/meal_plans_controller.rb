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

    existing = household.planned_meals.where(date: @week)
    if existing.exists? && !ActiveModel::Type::Boolean.new.cast(params[:replace])
      return render json: {
        error: "This week already has planned meals. Send replace: true to replace them.",
        planned_meals_count: existing.count
      }, status: :conflict
    end

    offset = @week.first - source.first
    PlannedMeal.transaction do
      existing.delete_all
      household.planned_meals.where(date: source, recipe_id: Recipe.visible_to(Current.user).select(:id)).find_each do |meal|
        household.planned_meals.create!(recipe_id: meal.recipe_id, meal_slot: meal.meal_slot, servings: meal.servings,
          date: meal.date + offset)
      end
    end
    render_week
  end

  private

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
