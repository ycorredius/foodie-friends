require "rails_helper"

RSpec.describe "API grocery list", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:household) { user.household }
  # Sunday 2026-11-01 through Saturday 2026-11-07.
  let(:sunday) { Date.new(2026, 11, 1) }
  let(:week) { {start_date: "2026-11-01", end_date: "2026-11-07"} }

  def ingredient(name, category = :other)
    Ingredient.find_or_create_by!(name: name) { |i| i.category = category }
  end

  # A 4-serving recipe with lines given as [name, quantity, unit] (category produce).
  def recipe_with(*lines, **attributes)
    create(:recipe, **attributes).tap do |recipe|
      lines.each_with_index do |(name, quantity, unit), position|
        recipe.recipe_ingredients.create!(ingredient: ingredient(name, :produce), quantity: quantity, unit: unit, position: position)
      end
    end
  end

  def plan(recipe, date = sunday, slot = :dinner, servings: 4)
    household.planned_meals.create!(recipe: recipe, date: date, meal_slot: slot, servings: servings)
  end

  def items
    response.parsed_body["sections"].flat_map { |section| section["items"] }
  end

  def item(name)
    items.find { |i| i["name"] == name }
  end

  it "combines the same ingredient across meals, scaled to each meal's servings" do
    soup = recipe_with(["milk", 1, "cup"], ["onion", 1, "each"])
    pie = recipe_with(["milk", 4, "tbsp"], ["onion", 2, "each"])
    plan(soup, servings: 8)
    plan(pie, sunday + 1.day)

    get api_v1_grocery_list_path, params: week, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("start_date" => "2026-11-01", "end_date" => "2026-11-07", "unavailable_meals_count" => 0)
    expect(item("milk")["amounts"]).to eq([{"quantity" => 2.25, "unit" => "cup"}])
    expect(item("onion")["amounts"]).to eq([{"quantity" => 4.0, "unit" => "each"}])
    expect(item("milk")["recipes"]).to eq([{"id" => soup.id, "title" => soup.title}, {"id" => pie.id, "title" => pie.title}])
  end

  it "lists a recipe planned twice once per item, counting both meals" do
    soup = recipe_with(["onion", 1, "each"])
    plan(soup)
    plan(soup, sunday + 1.day)

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(item("onion")).to include("amounts" => [{"quantity" => 2.0, "unit" => "each"}], "recipes" => [{"id" => soup.id, "title" => soup.title}])
  end

  it "converts to the user's unit system and keeps mass and volume apart" do
    user.update!(unit_system: :metric)
    plan(recipe_with(["flour", 2, "cup"], ["flour", 1, "lb"]))

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(item("flour")["amounts"]).to eq([{"quantity" => 473.0, "unit" => "ml"}, {"quantity" => 454.0, "unit" => "g"}])
  end

  it "lists ingredients without a quantity with no amounts" do
    plan(recipe_with(["salt", nil, nil]))

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(item("salt")["amounts"]).to eq([])
  end

  it "groups items by store section in aisle order, sorted by name" do
    recipe = create(:recipe)
    [["zucchini", :produce], ["butter", :dairy_eggs], ["apple", :produce], ["napkins", :other]].each_with_index do |(name, category), position|
      recipe.recipe_ingredients.create!(ingredient: ingredient(name, category), quantity: 1, unit: "each", position: position)
    end
    plan(recipe)

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(response.parsed_body["sections"].map { |s| [s["category"], s["items"].map { |i| i["name"] }] })
      .to eq([["produce", ["apple", "zucchini"]], ["dairy_eggs", ["butter"]], ["other", ["napkins"]]])
  end

  it "only uses meals in the date range" do
    plan(recipe_with(["onion", 1, "each"]), sunday - 1.day)
    plan(recipe_with(["leek", 1, "each"]), sunday + 2.days)
    plan(recipe_with(["kale", 1, "each"]), sunday + 3.days)

    get api_v1_grocery_list_path, params: {start_date: "2026-11-01", end_date: "2026-11-03"}, headers: headers
    expect(items.map { |i| i["name"] }).to eq(["leek"])
  end

  it "defaults to the current week, per the user's week start" do
    user.update!(week_start_day: :monday)
    plan(recipe_with(["onion", 1, "each"]), sunday)
    plan(recipe_with(["leek", 1, "each"]), sunday + 1.day)

    travel_to Time.zone.local(2026, 11, 4, 12) do
      get api_v1_grocery_list_path, headers: headers
    end
    expect(response.parsed_body).to include("start_date" => "2026-11-02", "end_date" => "2026-11-08")
    expect(items.map { |i| i["name"] }).to eq(["leek"])
  end

  it "leaves out meals whose recipe the user can no longer see, and counts them" do
    plan(recipe_with(["truffle", 1, "each"], visibility: :only_me))
    plan(recipe_with(["onion", 1, "each"]), sunday + 1.day)

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(items.map { |i| i["name"] }).to eq(["onion"])
    expect(response.parsed_body["unavailable_meals_count"]).to eq(1)
  end

  it "includes the user's own private recipes" do
    plan(recipe_with(["truffle", 1, "each"], user: user, visibility: :only_me))

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(items.map { |i| i["name"] }).to eq(["truffle"])
  end

  it "leaves out recipes by deactivated users" do
    author = create(:user)
    plan(recipe_with(["onion", 1, "each"], user: author))
    author.deactivate!

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(items).to eq([])
    expect(response.parsed_body["unavailable_meals_count"]).to eq(1)
  end

  it "only uses the user's own household" do
    create(:user).household.planned_meals.create!(recipe: recipe_with(["onion", 1, "each"]), date: sunday, meal_slot: :dinner, servings: 1)

    get api_v1_grocery_list_path, params: week, headers: headers
    expect(response.parsed_body).to include("sections" => [], "unavailable_meals_count" => 0)
  end

  it "rejects invalid or incomplete dates" do
    [{start_date: "2026-11-01"}, {start_date: "soon", end_date: "2026-11-07"}].each do |params|
      get api_v1_grocery_list_path, params: params, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]["dates"]).to eq(["start_date and end_date must both be dates like 2026-11-02"])
    end
  end

  it "rejects ranges that end before they start or are too long" do
    get api_v1_grocery_list_path, params: {start_date: "2026-11-07", end_date: "2026-11-01"}, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)

    get api_v1_grocery_list_path, params: {start_date: "2026-11-01", end_date: "2026-12-01"}, headers: headers
    expect(response).to have_http_status(:ok)
    get api_v1_grocery_list_path, params: {start_date: "2026-11-01", end_date: "2026-12-02"}, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "requires authentication" do
    get api_v1_grocery_list_path, params: week
    expect(response).to have_http_status(:unauthorized)
  end
end
