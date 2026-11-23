# One line of a grocery list: an ingredient, the total amounts needed and the
# recipes that need it. Name and category are copied from the ingredient so a
# saved list doesn't change when the catalog does.
#
# Amounts are stored as Unit.sum returns them (grams, millilitres or count
# units) and shown with Unit.display in each reader's unit system.
#
# Manual items are added by the household rather than generated from the
# plan (paper towels, milk for drinking). They're given a name and, optionally,
# a quantity, unit and category; see set_manual_details.
class GroceryListItem < ApplicationRecord
  # Store sections in roughly the order people walk a supermarket.
  SECTION_ORDER = %w[produce meat_seafood dairy_eggs bakery pantry spices frozen_foods beverages other].freeze

  belongs_to :grocery_list
  belongs_to :ingredient, optional: true

  enum :category, Ingredient.categories, validate: true
  # "bought" and "have" both mean there's nothing left to buy: bought on this
  # trip, or already in the kitchen.
  enum :status, {to_buy: 0, bought: 1, have: 2}, validate: true

  # What a manual item was given, e.g. 2 and "lb". Not stored: they're
  # turned into amounts, like a generated item's.
  attribute :quantity, :decimal
  attribute :unit, :string

  normalizes :name, with: ->(name) { name.squish }
  normalizes :unit, with: ->(unit) { unit.strip.downcase.presence }

  validates :name, presence: true, length: {maximum: 100}
  with_options if: :manual? do
    validates :quantity, numericality: {greater_than: 0}, allow_nil: true
    validates :unit, inclusion: {in: Unit.keys}, allow_nil: true
    validates :quantity, presence: true, if: :unit?
  end

  before_validation :set_manual_details, if: :manual?, on: :create

  # Items grouped by section in SECTION_ORDER, each sorted by name, as
  # [category, items] pairs.
  def self.sections(items)
    items.group_by(&:category).sort_by { |category, _items| SECTION_ORDER.index(category) }
      .map { |category, section_items| [category, section_items.sort_by { |item| item.name.downcase }] }
  end

  def amounts
    self[:amounts].map { |amount| Unit::Amount.new(BigDecimal(amount["quantity"]), amount["unit"]) }
  end

  def amounts=(amounts)
    self[:amounts] = amounts.map { |amount| {"quantity" => amount.quantity.to_s("F"), "unit" => amount.unit} }
  end

  private

  # Links a catalog ingredient whose name matches, so the item can be priced
  # like a generated one; it never adds to the catalog, so "paper towels"
  # doesn't become an ingredient. The category is the one given, else the
  # ingredient's, else "other". The amount is stored like a generated item's.
  def set_manual_details
    self.ingredient = Ingredient.find_by(name: Ingredient.normalize_value_for(:name, name.to_s))
    self.category = ingredient.category if ingredient && !category_came_from_user?
    self.amounts = Unit.sum([Unit::Amount.new(quantity, unit)])
  end
end
