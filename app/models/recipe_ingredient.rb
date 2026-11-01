# One ingredient line of a recipe, e.g. "2 cup flour, sifted". Quantity and
# unit are optional together, for lines like "salt, to taste".
class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :quantity, numericality: {greater_than: 0}, allow_nil: true
  validates :unit, inclusion: {in: Unit.keys}, allow_nil: true
  validates :quantity, presence: true, if: :unit?
  validates :note, length: {maximum: 200}

  normalizes :unit, with: ->(unit) { unit.strip.downcase.presence }

  delegate :name, :category, to: :ingredient

  def ingredient_name=(name)
    self.ingredient = Ingredient.find_or_initialize_by(name: Ingredient.normalize_value_for(:name, name.to_s))
  end

  # The amount to show a reader, scaled by factor and converted to their unit system.
  def amount_for(system:, factor: 1)
    Unit.convert(quantity, unit, system: system, factor: factor)
  end
end
