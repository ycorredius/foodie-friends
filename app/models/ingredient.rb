# A shared catalog of ingredients, referenced by recipe ingredient lines.
# Category drives grocery list grouping.
class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error

  enum :category, {
    other: 0, produce: 1, meat_seafood: 2, dairy_eggs: 3, bakery: 4,
    pantry: 5, spices: 6, frozen_foods: 7, beverages: 8
  }, validate: true

  normalizes :name, with: ->(name) { name.squish.downcase }

  validates :name, presence: true, uniqueness: true, length: {maximum: 100}
end
