# A user's saved recipe. Keeps Recipe#saves_count up to date.
class SavedRecipe < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: :saves_count

  validates :recipe_id, uniqueness: {scope: :user_id}
end
