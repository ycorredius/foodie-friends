# == Schema Information
#
# Table name: recipes
#
#  id           :bigint           not null, primary key
#  avatar       :string
#  cook_time    :integer
#  ingredients  :text
#  instructions :text
#  is_private   :boolean          default(FALSE)
#  meal_type    :integer
#  name         :string
#  prep_time    :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer
#

class Recipe < ApplicationRecord
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  has_many :comments, class_name: 'Comment'
  has_one_attached :image

  validates :name, presence: true
  validates :ingredients, presence: true, length: { minimum: 10, maximum: 500 }
  validates :instructions, presence: true, length: { minimum: 10, maximum: 500 }
  validates :meal_type, presence: true

  scope :search , -> (search) { where("lower(name) LIKE ?", "%#{search}%") }

  after_update_commit { broadcast_update }

  enum :meal_type, [ :dinner, :lunch, :breakfast, :desert, :appetizer, :brunch, :side_dish, :other]
end
