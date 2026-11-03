# A reusable week of meals, saved from a household's plan. Meals are stored by
# weekday rather than date, so the template can be applied to any week.
class PlanTemplate < ApplicationRecord
  belongs_to :household
  has_many :meals, -> { order(:wday, :meal_slot, :id) }, class_name: "PlanTemplateMeal", dependent: :destroy

  validates :name, presence: true, length: {maximum: 60}, uniqueness: {scope: :household_id}

  # Builds a template from the planned meals on the given dates, keeping only
  # recipes the user can still see.
  def self.build_from(household:, user:, dates:, name:)
    new(household: household, name: name).tap do |template|
      household.planned_meals.between(dates).where(recipe_id: Recipe.visible_to(user).select(:id)).each do |meal|
        template.meals.build(recipe_id: meal.recipe_id, wday: meal.date.wday, meal_slot: meal.meal_slot, servings: meal.servings)
      end
    end
  end
end
