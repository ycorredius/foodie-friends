require "rails_helper"

RSpec.describe RecipeIngredient, type: :model do
  it "accepts a quantity without a unit, and neither for 'to taste' lines" do
    expect(build(:recipe_ingredient, quantity: 2, unit: nil)).to be_valid
    expect(build(:recipe_ingredient, quantity: nil, unit: nil)).to be_valid
  end

  it "requires a quantity when a unit is given" do
    expect(build(:recipe_ingredient, quantity: nil, unit: "cup")).not_to be_valid
  end

  it "rejects unknown units and non-positive quantities" do
    expect(build(:recipe_ingredient, unit: "handful")).not_to be_valid
    expect(build(:recipe_ingredient, quantity: 0)).not_to be_valid
  end

  it "normalizes the unit" do
    expect(build(:recipe_ingredient, unit: " TBSP ").unit).to eq("tbsp")
    expect(build(:recipe_ingredient, quantity: 1, unit: " ").unit).to be_nil
  end
end
