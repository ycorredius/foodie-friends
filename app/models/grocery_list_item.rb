# One line of a grocery list: an ingredient, the total amounts needed and the
# recipes that need it. Name and category are copied from the ingredient so a
# saved list doesn't change when the catalog does.
#
# Amounts are stored as Unit.sum returns them (grams, millilitres or count
# units) and shown with Unit.display in each reader's unit system.
class GroceryListItem < ApplicationRecord
  # Store sections in roughly the order people walk a supermarket.
  SECTION_ORDER = %w[produce meat_seafood dairy_eggs bakery pantry spices frozen_foods beverages other].freeze

  belongs_to :grocery_list
  belongs_to :ingredient, optional: true

  enum :category, Ingredient.categories, validate: true
  # "bought" and "have" both mean there's nothing left to buy: bought on this
  # trip, or already in the kitchen.
  enum :status, {to_buy: 0, bought: 1, have: 2}, validate: true

  validates :name, presence: true, length: {maximum: 100}

  # Items grouped by section in SECTION_ORDER, each sorted by name, as
  # [category, items] pairs.
  def self.sections(items)
    items.group_by(&:category).sort_by { |category, _items| SECTION_ORDER.index(category) }
      .map { |category, section_items| [category, section_items.sort_by(&:name)] }
  end

  def amounts
    self[:amounts].map { |amount| Unit::Amount.new(BigDecimal(amount["quantity"]), amount["unit"]) }
  end

  def amounts=(amounts)
    self[:amounts] = amounts.map { |amount| {"quantity" => amount.quantity.to_s("F"), "unit" => amount.unit} }
  end
end
