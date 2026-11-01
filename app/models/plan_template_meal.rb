class PlanTemplateMeal < ApplicationRecord
  belongs_to :plan_template
  belongs_to :recipe

  enum :meal_slot, PlannedMeal.meal_slots, validate: true

  validates :wday, inclusion: {in: 0..6}
  validates :servings, numericality: {only_integer: true, in: 1..100}

  def weekday
    Date::DAYNAMES[wday].downcase
  end
end
