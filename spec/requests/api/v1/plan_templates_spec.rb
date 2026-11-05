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

  describe "POST /api/v1/meal_plans/:date/apply_template" do
    # Saved from Sunday 2026-11-01: Sunday breakfast (4 servings), Wednesday dinner.
    let!(:template) do
      plan(sunday, :breakfast, servings: 4)
      plan(sunday + 3.days, :dinner)
      PlanTemplate.build_from(household: household, user: user, dates: sunday..(sunday + 6.days), name: "Usual").tap(&:save!)
    end
    let(:next_week) { "2026-11-10" }

    def apply(date = next_week, template_id: template.id, **params)
      post api_v1_apply_template_meal_plan_path(date), params: {plan_template_id: template_id, **params}, headers: headers, as: :json
    end

    def planned
      response.parsed_body["planned_meals"].map { |m| [m["date"], m["meal_slot"], m["servings"]] }
    end

    it "plans the template's meals on the matching weekdays" do
      apply

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("week_start" => "2026-11-08", "skipped_meals_count" => 0)
      expect(planned).to eq([["2026-11-08", "breakfast", 4], ["2026-11-11", "dinner", 2]])
      expect(household.planned_meals.count).to eq(4)
    end

    it "matches weekdays, not positions, when the week starts on Monday" do
      user.update!(week_start_day: :monday)
      apply
      expect(response.parsed_body["week_start"]).to eq("2026-11-09")
      expect(planned).to eq([["2026-11-11", "dinner", 2], ["2026-11-15", "breakfast", 4]])
    end

    it "refuses to overwrite a week with meals unless replace is true" do
      existing = plan(sunday + 7.days, :lunch)

      apply
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to include("planned_meals_count" => 1)
      expect(household.planned_meals.where(date: sunday + 7.days..sunday + 13.days).count).to eq(1)

      apply(replace: true)
      expect(response).to have_http_status(:ok)
      expect(PlannedMeal.exists?(existing.id)).to be(false)
      expect(planned.map(&:second)).to eq(%w[breakfast dinner])
    end

    it "leaves out and counts recipes the user can no longer see" do
      hidden = create(:recipe)
      template.meals.create!(recipe: hidden, wday: 5, meal_slot: :lunch, servings: 2)
      hidden.update!(visibility: :only_me)

      apply
      expect(response.parsed_body["skipped_meals_count"]).to eq(1)
      expect(planned.map(&:second)).to eq(%w[breakfast dinner])
    end

    it "changes nothing when none of the template's recipes are visible" do
      existing = plan(sunday + 7.days, :lunch)
      recipe.update!(visibility: :only_me)

      apply(replace: true)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("plan_template_id")
      expect(PlannedMeal.exists?(existing.id)).to be(true)
    end

    it "only applies the household's own templates" do
      other = create(:user)
      post api_v1_apply_template_meal_plan_path(next_week), params: {plan_template_id: template.id},
        headers: {Authorization: "Bearer #{create(:session, user: other).token}"}, as: :json
      expect(response).to have_http_status(:not_found)
      expect(other.household.planned_meals.count).to eq(0)
    end

    it "rejects invalid dates and a missing template" do
      apply("soon")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("date")

      post api_v1_apply_template_meal_plan_path(next_week), headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end
end
