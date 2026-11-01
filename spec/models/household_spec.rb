require "rails_helper"

RSpec.describe Household, type: :model do
  it "is created for every new user" do
    user = create(:user, first_name: "Ada")
    expect(user.household).to have_attributes(name: "Ada's household", size: 1)
    expect(user.household.members).to eq([user])
  end

  it "validates name and size" do
    household = create(:user).household
    expect(household.update(name: "", size: 0)).to be(false)
    expect(household.errors.attribute_names).to contain_exactly(:name, :size)
  end

  it "is deleted, with its planned meals, when its last member is deleted" do
    user = create(:user)
    household = user.household
    household.planned_meals.create!(recipe: create(:recipe), date: Date.current, meal_slot: :dinner, servings: 2)

    user.destroy

    expect(Household.exists?(household.id)).to be(false)
    expect(PlannedMeal.count).to eq(0)
  end

  describe "User#week_containing" do
    let(:wednesday) { Date.new(2026, 11, 4) }

    it "starts weeks on Sunday by default" do
      expect(create(:user).week_containing(wednesday)).to eq(Date.new(2026, 11, 1)..Date.new(2026, 11, 7))
    end

    it "starts weeks on Monday when the user chooses" do
      user = create(:user, week_start_day: :monday)
      expect(user.week_containing(wednesday)).to eq(Date.new(2026, 11, 2)..Date.new(2026, 11, 8))
    end
  end
end
