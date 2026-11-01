# Adding, changing and removing meals in the current user's household plan.
class Api::V1::PlannedMealsController < Api::V1::BaseController
  before_action :set_planned_meal, only: %i[update destroy]

  # Only recipes the user can see can be planned. Servings default to the
  # household size. Adding a recipe already planned for that date and slot
  # returns the existing meal (200), so retries and double taps are harmless.
  def create
    attributes = params.expect(planned_meal: [:recipe_id, :date, :meal_slot, :servings])
    recipe = Recipe.visible_to(Current.user).find_by(id: attributes[:recipe_id])
    unless recipe
      return render json: {errors: {recipe_id: ["is not a recipe you can see"]}}, status: :unprocessable_entity
    end

    @planned_meal = household.planned_meals.new(attributes.except(:recipe_id).merge(recipe: recipe))
    @planned_meal.servings ||= household.size
    if (existing = find_same_meal)
      @planned_meal = existing
      render :show
    elsif @planned_meal.save
      render :show, status: :created
    else
      render_errors
    end
  rescue ActiveRecord::RecordNotUnique
    @planned_meal = find_same_meal
    render :show
  end

  # Moves a meal to another date or slot, or changes its servings. Requires the
  # lock_version the client last saw; if the meal changed since, responds 409
  # with its current state instead of overwriting the other change.
  def update
    attributes = params.expect(planned_meal: [:date, :meal_slot, :servings, :lock_version])
    unless attributes.key?(:lock_version)
      return render json: {errors: {lock_version: ["is required"]}}, status: :unprocessable_entity
    end

    if @planned_meal.update(attributes)
      render :show
    else
      render_errors
    end
  rescue ActiveRecord::StaleObjectError
    @planned_meal.reload
    render :conflict, status: :conflict
  end

  def destroy
    @planned_meal.destroy
    head :no_content
  end

  private

  def household
    Current.user.household
  end

  def find_same_meal
    household.planned_meals.find_by(recipe: @planned_meal.recipe, date: @planned_meal.date, meal_slot: @planned_meal.meal_slot)
  end

  def set_planned_meal
    @planned_meal = household.planned_meals.find(params[:id])
  end

  def render_errors
    render json: {errors: @planned_meal.errors}, status: :unprocessable_entity
  end
end
