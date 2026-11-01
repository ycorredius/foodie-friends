class Recipe < ApplicationRecord
  belongs_to :user
  # Lines are validated by ingredient_lines_are_valid, which reports errors by
  # position in the submitted list rather than in the association.
  has_many :recipe_ingredients, -> { order(:position) }, dependent: :destroy, autosave: true, validate: false
  has_many :ingredients, through: :recipe_ingredients

  enum :meal_type, %i[breakfast lunch dinner snack dessert appetizer side drink], validate: {allow_nil: true}
  enum :difficulty, %i[easy medium hard], validate: {allow_nil: true}
  enum :visibility, {public: 0, only_me: 1}, prefix: true, validate: true

  validates :title, presence: true, length: {maximum: 120}
  validates :description, length: {maximum: 2000}
  validates :servings, numericality: {only_integer: true, in: 1..100}
  validates :prep_minutes, :cook_minutes, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validate :steps_are_present_strings
  validate :ingredient_lines_are_valid

  # Recipes the user may view. Phase 2 extends this to followers of private profiles.
  scope :visible_to, ->(user) { visibility_public.or(where(user: user)) }

  def total_minutes
    (prep_minutes || 0) + (cook_minutes || 0) if prep_minutes || cook_minutes
  end

  # Replaces all ingredient lines. Each line is a hash with name, quantity, unit and note.
  def ingredient_lines=(lines)
    recipe_ingredients.each(&:mark_for_destruction)
    lines.each_with_index do |line, position|
      recipe_ingredients.build(
        ingredient_name: line[:name], quantity: line[:quantity], unit: line[:unit], note: line[:note], position: position
      )
    end
  end

  private

  # Errors are keyed like "ingredients[1].unit", matching the API's ingredients param.
  def ingredient_lines_are_valid
    recipe_ingredients.reject(&:marked_for_destruction?).each_with_index do |line, index|
      next if line.valid?

      line.errors.each { |error| errors.add(:"ingredients[#{index}].#{error.attribute}", error.message) }
    end
  end

  def steps_are_present_strings
    errors.add(:steps, "must be a list of non-blank text") unless steps.is_a?(Array) && steps.all?(&:present?)
  end
end
