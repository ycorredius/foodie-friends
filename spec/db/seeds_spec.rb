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

  context "in development" do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("development")) }

    let(:demo) { User.find_by!(email_address: "demo@example.com") }
    let(:this_week) { demo.week_containing(Date.current) }

    it "plans this week for the demo account, leaving the third day empty" do
      Rails.application.load_seed

      meals = demo.household.planned_meals.where(date: this_week)
      expect(meals.count).to eq(9)
      expect(meals.pluck(:date)).not_to include(this_week.first + 2)
      expect(meals.map(&:recipe)).to all(have_attributes(user: kitchen))
    end

    it "doesn't touch a week that already has meals" do
      Rails.application.load_seed
      demo.household.planned_meals.where(date: this_week).where.not(meal_slot: :dinner).destroy_all

      expect { Rails.application.load_seed }.not_to change { demo.household.planned_meals.count }
    end
  end
end
