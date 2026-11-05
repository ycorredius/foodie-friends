# Works out what to buy for a household's planned meals over a range of
# dates, as unsaved GroceryListItems: GET /grocery_lists/preview shows them and
# GroceryList.generate saves them.
#
# Each recipe's ingredient lines are scaled to the meal's servings, then lines
# for the same ingredient are added up with Unit.sum. Each item lists the
# recipes that need it. Meals whose recipe the user can no longer see are left
# out and counted in unavailable_meals_count.
class GroceryListBuilder
  attr_reader :dates

  def initialize(household:, user:, dates:)
    @household = household
    @user = user
    @dates = dates
  end

  def items
    lines = visible_meals.flat_map do |meal|
      factor = BigDecimal(meal.servings) / meal.recipe.servings
      meal.recipe.recipe_ingredients.map do |line|
        [line, meal.recipe_id, Unit::Amount.new(line.quantity && line.quantity * factor, line.unit)]
      end
    end

    lines.group_by { |line, _recipe_id, _amount| line.ingredient }.map do |ingredient, group|
      GroceryListItem.new(
        ingredient: ingredient,
        name: ingredient.name,
        category: ingredient.category,
        amounts: Unit.sum(group.map(&:last)),
        recipe_ids: group.map(&:second).uniq
      )
    end
  end

  def unavailable_meals_count
    meals.size - visible_meals.size
  end

  private

  def meals
    @meals ||= @household.planned_meals.between(dates).to_a
  end

  def visible_meals
    @visible_meals ||= begin
      visible_ids = Recipe.visible_to(@user).where(id: meals.map(&:recipe_id)).pluck(:id).to_set
      meals.select { |meal| visible_ids.include?(meal.recipe_id) }.tap do |visible|
        ActiveRecord::Associations::Preloader.new(records: visible, associations: {recipe: {recipe_ingredients: :ingredient}}).call
      end
    end
  end
end
