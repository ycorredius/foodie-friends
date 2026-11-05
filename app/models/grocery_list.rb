# A household's saved grocery list, generated from the planned meals between
# start_date and end_date (see GroceryListBuilder). It's a snapshot: later
# changes to the plan don't change it.
class GroceryList < ApplicationRecord
  belongs_to :household
  has_many :items, class_name: "GroceryListItem", dependent: :delete_all

  validates :name, length: {maximum: 60}
  validates :start_date, :end_date, presence: true
end
