require "rails_helper"

RSpec.describe "db/seeds.rb" do
  let(:kitchen) { User.find_by!(email_address: "kitchen@foodiefriends.example") }

  def counts
    [User.count, Recipe.count, Ingredient.count, RecipeIngredient.count]
  end

  it "creates public starter recipes owned by the kitchen account" do
    Rails.application.load_seed

    expect(kitchen.recipes.count).to eq(10)
    expect(kitchen.recipes).to all(be_visibility_public)
    expect(kitchen.recipes.joins(:recipe_ingredients).distinct.count).to eq(10)
  end

  it "categorizes every ingredient the starter recipes use" do
    Rails.application.load_seed
    expect(Ingredient.joins(:recipe_ingredients).where(category: :other).distinct.pluck(:name)).to be_empty
  end

  it "is idempotent" do
    Rails.application.load_seed
    first_run = counts
    Rails.application.load_seed
    expect(counts).to eq(first_run)
  end

  it "categorizes ingredients users already created" do
    create(:ingredient, name: "garlic", category: :other)
    Rails.application.load_seed
    expect(Ingredient.find_by!(name: "garlic")).to be_produce
  end

  it "doesn't create the development login outside development" do
    Rails.application.load_seed
    expect(User.exists?(email_address: "demo@example.com")).to be(false)
  end
end
