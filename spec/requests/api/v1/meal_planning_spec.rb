require "rails_helper"

RSpec.describe "API meal planning", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:household) { user.household }
  let(:recipe) { create(:recipe) }
  # Sunday 2026-11-01 through Saturday 2026-11-07.
  let(:sunday) { Date.new(2026, 11, 1) }

  def plan(date, slot = :dinner, recipe: self.recipe, servings: 2)
    household.planned_meals.create!(recipe: recipe, date: date, meal_slot: slot, servings: servings)
  end

  def meal_dates
    response.parsed_body["planned_meals"].map { |m| m["date"] }
  end

  describe "household" do
    it "shows and updates the household" do
      get api_v1_household_path, headers: headers
      expect(response.parsed_body).to include("name" => household.name, "size" => 1)
      expect(response.parsed_body["members"].map { |m| m["id"] }).to eq([user.id])

      patch api_v1_household_path, params: {household: {name: "The Smiths", size: 4}}, headers: headers, as: :json
      expect(response.parsed_body).to include("name" => "The Smiths", "size" => 4)
    end

    it "rejects invalid sizes" do
      patch api_v1_household_path, params: {household: {size: 0}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/meal_plans/:date" do
    it "returns the week containing the date, in order, with recipes" do
      plan(sunday + 2.days, :dinner)
      plan(sunday + 2.days, :breakfast)
      plan(sunday + 7.days)
      plan(sunday - 1.day)

      get api_v1_meal_plan_path("2026-11-04"), headers: headers

      body = response.parsed_body
      expect(body).to include("week_start" => "2026-11-01", "week_end" => "2026-11-07")
      expect(body["planned_meals"].map { |m| [m["date"], m["meal_slot"]] }).to eq([["2026-11-03", "breakfast"], ["2026-11-03", "dinner"]])
      expect(body["planned_meals"].first["recipe"]).to include("id" => recipe.id, "title" => recipe.title)
    end

    it "follows the user's week start day" do
      user.update!(week_start_day: :monday)
      plan(sunday)
      plan(sunday + 1.day)

      get api_v1_meal_plan_path("2026-11-04"), headers: headers
      expect(response.parsed_body).to include("week_start" => "2026-11-02", "week_end" => "2026-11-08")
      expect(meal_dates).to eq(["2026-11-02"])
    end

    it "returns an empty week when nothing is planned" do
      get api_v1_meal_plan_path("2026-11-04"), headers: headers
      expect(response.parsed_body["planned_meals"]).to eq([])
    end

    it "marks meals whose recipe became hidden as unavailable" do
      plan(sunday)
      recipe.update!(visibility: :only_me)

      get api_v1_meal_plan_path("2026-11-01"), headers: headers
      expect(response.parsed_body["planned_meals"].first).to include("unavailable" => true, "recipe" => nil)
    end

    it "only shows the user's own household" do
      create(:user).household.planned_meals.create!(recipe: recipe, date: sunday, meal_slot: :dinner, servings: 1)
      get api_v1_meal_plan_path("2026-11-01"), headers: headers
      expect(response.parsed_body["planned_meals"]).to eq([])
    end

    it "rejects invalid dates" do
      get api_v1_meal_plan_path("next-tuesday"), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "planned meals" do
    it "adds a meal with servings defaulting to the household size" do
      household.update!(size: 4)
      post api_v1_planned_meals_path, headers: headers, as: :json,
        params: {planned_meal: {recipe_id: recipe.id, date: "2026-11-03", meal_slot: "dinner"}}

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("date" => "2026-11-03", "meal_slot" => "dinner", "servings" => 4, "unavailable" => false)
    end

    it "allows several recipes in one slot" do
      2.times do
        post api_v1_planned_meals_path, headers: headers, as: :json,
          params: {planned_meal: {recipe_id: create(:recipe).id, date: "2026-11-03", meal_slot: "dinner"}}
      end
      expect(household.planned_meals.count).to eq(2)
    end

    it "can't plan a recipe the user can't see" do
      hidden = create(:recipe, :only_me)
      post api_v1_planned_meals_path, headers: headers, as: :json,
        params: {planned_meal: {recipe_id: hidden.id, date: "2026-11-03", meal_slot: "dinner"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("recipe_id")
    end

    it "rejects invalid slots" do
      post api_v1_planned_meals_path, headers: headers, as: :json,
        params: {planned_meal: {recipe_id: recipe.id, date: "2026-11-03", meal_slot: "brunch"}}
      expect(response.parsed_body["errors"]).to have_key("meal_slot")
    end

    it "returns the existing meal when the same recipe is added to a slot twice" do
      params = {planned_meal: {recipe_id: recipe.id, date: "2026-11-03", meal_slot: "dinner"}}
      post api_v1_planned_meals_path, params: params, headers: headers, as: :json
      first_id = response.parsed_body["id"]

      post api_v1_planned_meals_path, params: params, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(first_id)
      expect(household.planned_meals.count).to eq(1)
    end

    it "won't move a meal into a slot that already has the same recipe" do
      plan(sunday, :dinner)
      lunch = plan(sunday, :lunch)
      patch api_v1_planned_meal_path(lunch), headers: headers, as: :json,
        params: {planned_meal: {meal_slot: "dinner", lock_version: lunch.lock_version}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to eq("recipe_id" => ["is already planned for this meal"])
    end

    it "requires lock_version to edit" do
      meal = plan(sunday)
      patch api_v1_planned_meal_path(meal), params: {planned_meal: {servings: 6}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(meal.reload.servings).to eq(2)
    end

    it "rejects an edit based on a stale version with the current state" do
      meal = plan(sunday)
      stale_version = meal.lock_version
      meal.update!(servings: 5)

      patch api_v1_planned_meal_path(meal), headers: headers, as: :json,
        params: {planned_meal: {date: "2026-11-05", lock_version: stale_version}}

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["planned_meal"]).to include("date" => "2026-11-01", "servings" => 5, "lock_version" => stale_version + 1)
      expect(meal.reload.date).to eq(sunday)
    end

    it "moves, resizes and removes a meal" do
      meal = plan(sunday)
      patch api_v1_planned_meal_path(meal), headers: headers, as: :json,
        params: {planned_meal: {date: "2026-11-05", meal_slot: "lunch", servings: 6, lock_version: meal.lock_version}}
      expect(response.parsed_body).to include("date" => "2026-11-05", "meal_slot" => "lunch", "servings" => 6,
        "lock_version" => meal.lock_version + 1)

      delete api_v1_planned_meal_path(meal), headers: headers
      expect(response).to have_http_status(:no_content)
      expect(PlannedMeal.exists?(meal.id)).to be(false)
    end

    it "can't change another household's meals" do
      other = create(:user).household.planned_meals.create!(recipe: recipe, date: sunday, meal_slot: :dinner, servings: 1)
      delete api_v1_planned_meal_path(other), headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "removes meals when their recipe is deleted" do
      plan(sunday)
      recipe.destroy
      expect(household.planned_meals.count).to eq(0)
    end
  end

  describe "POST /api/v1/meal_plans/:date/copy" do
    let(:next_week) { "2026-11-10" }

    it "copies the previous week onto the same weekdays" do
      plan(sunday, :dinner, servings: 3)
      plan(sunday + 3.days, :lunch)

      post api_v1_copy_meal_plan_path(next_week), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["planned_meals"].map { |m| [m["date"], m["meal_slot"], m["servings"]] })
        .to eq([["2026-11-08", "dinner", 3], ["2026-11-11", "lunch", 2]])
      expect(household.planned_meals.count).to eq(4)
    end

    it "copies from a chosen week" do
      plan(sunday - 14.days)
      post api_v1_copy_meal_plan_path(next_week, from: (sunday - 14.days).iso8601), headers: headers
      expect(meal_dates).to eq(["2026-11-08"])
    end

    it "refuses to overwrite a week with meals unless replace is true" do
      plan(sunday)
      existing = plan(sunday + 7.days, :breakfast)

      post api_v1_copy_meal_plan_path(next_week), headers: headers
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to include("planned_meals_count" => 1)

      post api_v1_copy_meal_plan_path(next_week, replace: true), headers: headers
      expect(response).to have_http_status(:ok)
      expect(PlannedMeal.exists?(existing.id)).to be(false)
      expect(response.parsed_body["planned_meals"].map { |m| m["meal_slot"] }).to eq(["dinner"])
    end

    it "skips recipes the user can no longer see" do
      plan(sunday)
      plan(sunday, :lunch, recipe: create(:recipe, :only_me))
      post api_v1_copy_meal_plan_path(next_week), headers: headers
      expect(response.parsed_body["planned_meals"].size).to eq(1)
    end

    it "rejects copying a week onto itself" do
      post api_v1_copy_meal_plan_path(next_week, from: next_week), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
