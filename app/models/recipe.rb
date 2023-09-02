# == Schema Information
#
# Table name: recipes
#
#  id           :bigint           not null, primary key
#  avatar       :string
#  ingredients  :text
#  instructions :text
#  is_private   :boolean          default(FALSE)
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer
#

#TODO: Build out a recipe search for category and ingredients separately.
#TODO: Building recipe associations to able to be use without manual iteration through each param
class Recipe < ApplicationRecord
    belongs_to :user
    has_many :recipe_categories
    has_many :categories, through: :recipe_categories
    has_one_attached :image
    

    accepts_nested_attributes_for :ingredients, allow_destroy: true
    accepts_nested_attributes_for :categories, allow_destroy: true
    accepts_nested_attributes_for :instructions, allow_destroy: true

end
