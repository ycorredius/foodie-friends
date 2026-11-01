require "rails_helper"

RSpec.describe "API plan templates", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:household) { user.household }
  let(:recipe) { create(:recipe) }
  # Sunday 2026-11-01 through Saturday 2026-11-07.
  let(:sunday) { Date.new(2026, 11, 1) }

  def plan(date, slot = :dinner, recipe: self.recipe, servings: 2)
    household.planned_meals.create!(recipe: recipe, date: date, meal_slot: slot, servings: servings)
  end

  def save_template(name: "Busy week", date: "2026-11-04")
    post api_v1_plan_templates_path, params: {plan_template: {name: name, date: date}}, headers: headers, as: :json
  end

  describe "POST /api/v1/plan_templates" do
    it "saves the week's meals by weekday" do
      plan(sunday, :breakfast, servings: 4)
      plan(sunday + 3.days, :dinner)
      plan(sunday + 7.days)

      save_template

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include("name" => "Busy week", "meals_count" => 2)
      expect(body["meals"].map { |m| [m["weekday"], m["meal_slot"], m["servings"]] })
        .to eq([["sunday", "breakfast", 4], ["wednesday", "dinner", 2]])
      expect(body["meals"].first["recipe"]).to include("id" => recipe.id)
    end

    it "uses the user's week start to pick the week" do
      user.update!(week_start_day: :monday)
      plan(sunday)
      plan(sunday + 1.day, :lunch)

      save_template(date: "2026-11-04")
      expect(response.parsed_body["meals"].map { |m| m["weekday"] }).to eq(["monday"])
    end

    it "leaves out recipes the user can no longer see" do
      plan(sunday)
      plan(sunday, :lunch, recipe: create(:recipe, :only_me))
      save_template
      expect(response.parsed_body["meals_count"]).to eq(1)
    end

    it "rejects a week with no meals" do
      save_template
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("date")
      expect(PlanTemplate.count).to eq(0)
    end

    it "rejects a missing or duplicate name and invalid dates" do
      plan(sunday)
      save_template(name: "")
      expect(response.parsed_body["errors"]).to have_key("name")

      save_template
      save_template
      expect(response.parsed_body["errors"]).to eq("name" => ["has already been taken"])

      save_template(name: "Other", date: "soon")
      expect(response.parsed_body["errors"]).to have_key("date")
    end
  end

  describe "listing, viewing and deleting" do
    let!(:template) do
      plan(sunday)
      PlanTemplate.build_from(household: household, user: user, dates: sunday..(sunday + 6.days), name: "Usual").tap(&:save!)
    end

    it "lists the household's templates, newest first" do
      newer = PlanTemplate.build_from(household: household, user: user, dates: sunday..(sunday + 6.days), name: "Newer").tap(&:save!)
      get api_v1_plan_templates_path, headers: headers
      expect(response.parsed_body["plan_templates"].map { |t| [t["name"], t["meals_count"]] }).to eq([["Newer", 1], ["Usual", 1]])
      expect(response.parsed_body["plan_templates"].first["id"]).to eq(newer.id)
    end

    it "marks meals whose recipe became hidden as unavailable" do
      recipe.update!(visibility: :only_me)
      get api_v1_plan_template_path(template), headers: headers
      expect(response.parsed_body["meals"].first).to include("unavailable" => true, "recipe" => nil)
    end

    it "deletes a template" do
      delete api_v1_plan_template_path(template), headers: headers
      expect(response).to have_http_status(:no_content)
      expect(PlanTemplate.count).to eq(0)
      expect(PlanTemplateMeal.count).to eq(0)
    end

    it "keeps templates when the planned meals they came from change" do
      household.planned_meals.destroy_all
      get api_v1_plan_template_path(template), headers: headers
      expect(response.parsed_body["meals_count"]).to eq(1)
    end

    it "removes template meals when their recipe is deleted" do
      recipe.destroy
      expect(template.meals.reload).to be_empty
    end

    it "hides other households' templates" do
      other = create(:user)
      get api_v1_plan_template_path(template), headers: {Authorization: "Bearer #{create(:session, user: other).token}"}
      expect(response).to have_http_status(:not_found)
      delete api_v1_plan_template_path(template), headers: {Authorization: "Bearer #{create(:session, user: other).token}"}
      expect(PlanTemplate.exists?(template.id)).to be(true)
    end
  end
end
