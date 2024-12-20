# frozen_string_literal: true

# == Schema Information
#
# Table name: recipe_ingredients
#
#  id            :bigint           not null, primary key
#  quantity      :string           default("")
#  unit          :string           default("")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ingredient_id :integer
#  recipe_id     :integer
#
class RecipeIngredientSerializer
  include FastJsonapi::ObjectSerializer

  attributes :name, &:name
end
