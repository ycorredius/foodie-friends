# Works out what to buy for a household's planned meals over a range of
# dates. Nothing is stored: the list is computed from the plan on each call.
#
# Each recipe's ingredient lines are scaled to the meal's servings, then lines
# for the same ingredient are added up with Unit.sum in the user's unit
# system. Items are grouped by store section (Ingredient#category) and list
# the recipes that need them. Meals whose recipe the user can no longer see
# are left out and counted in unavailable_meals_count.
class GroceryListBuilder
  Item = Data.define(:ingredient, :amounts, :recipes)
  Section = Data.define(:category, :items)

  # Store sections in roughly the order people walk a supermarket.
  SECTION_ORDER = %w[produce meat_seafood dairy_eggs bakery pantry spices frozen_foods beverages other].freeze

  attr_reader :dates

  def initialize(household:, user:, dates:)
    @household = household
    @user = user
    @dates = dates
  end

  def sections
    @sections ||= items.group_by { |item| item.ingredient.category }
      .sort_by { |category, _items| SECTION_ORDER.index(category) }
      .map { |category, items| Section.new(category, items.sort_by { |item| item.ingredient.name }) }
  end

  def unavailable_meals_count
    meals.size - visible_meals.size
  end

  private

  def items
    lines = visible_meals.flat_map do |meal|
      factor = BigDecimal(meal.servings) / meal.recipe.servings
      meal.recipe.recipe_ingredients.map do |line|
        [line, meal.recipe, Unit::Amount.new(line.quantity && line.quantity * factor, line.unit)]
      end
    end

    lines.group_by { |line, _recipe, _amount| line.ingredient }.map do |ingredient, group|
      Item.new(
        ingredient: ingredient,
        amounts: Unit.sum(group.map(&:last), system: @user.unit_system),
        recipes: group.map(&:second).uniq
      )
    end
  end

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
