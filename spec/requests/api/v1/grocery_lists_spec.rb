require "rails_helper"

RSpec.describe "API saved grocery lists", type: :request do
  let(:user) { create(:user) }
  let(:headers) { {Authorization: "Bearer #{create(:session, user: user).token}"} }
  let(:household) { user.household }
  # Sunday 2026-11-01 through Saturday 2026-11-07.
  let(:sunday) { Date.new(2026, 11, 1) }
  let(:week) { {start_date: "2026-11-01", end_date: "2026-11-07"} }

  # A 4-serving recipe with lines given as [name, quantity, unit].
  def recipe_with(*lines, **attributes)
    create(:recipe, **attributes).tap do |recipe|
      lines.each_with_index do |(name, quantity, unit), position|
        ingredient = Ingredient.find_or_create_by!(name: name) { |i| i.category = :produce }
        recipe.recipe_ingredients.create!(ingredient: ingredient, quantity: quantity, unit: unit, position: position)
      end
    end
  end

  def plan(recipe, date = sunday, servings: 4)
    household.planned_meals.create!(recipe: recipe, date: date, meal_slot: :dinner, servings: servings)
  end

  def create_list(**params)
    post api_v1_grocery_lists_path, params: {grocery_list: week.merge(params)}, headers: headers, as: :json
    household.grocery_lists.find(response.parsed_body["id"])
  end

  def items
    response.parsed_body["sections"].flat_map { |section| section["items"] }
  end

  def item(name)
    items.find { |i| i["name"] == name }
  end

  describe "POST /api/v1/grocery_lists" do
    it "saves the list worked out from the plan" do
      soup = recipe_with(["milk", 1, "cup"], ["onion", 1, "each"])
      plan(soup, servings: 8)
      plan(recipe_with(["milk", 4, "tbsp"]), sunday + 1.day)

      list = create_list(name: "Big shop")

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("name" => "Big shop", "start_date" => "2026-11-01", "end_date" => "2026-11-07",
        "unavailable_meals_count" => 0)
      expect(item("milk")).to include("id" => list.items.find_by!(name: "milk").id, "status" => "to_buy",
        "amounts" => [{"quantity" => 2.25, "unit" => "cup"}])
      expect(item("onion")).to include("amounts" => [{"quantity" => 2.0, "unit" => "each"}],
        "recipes" => [{"id" => soup.id, "title" => soup.title}])
      expect(list.items.count).to eq(2)
    end

    it "stores amounts in grams and millilitres so each reader sees their own unit system" do
      plan(recipe_with(["milk", 1, "cup"]))
      list = create_list

      expect(list.items.first.amounts).to eq([Unit::Amount.new(BigDecimal("236.5882365"), "ml")])
      user.update!(unit_system: :metric)
      get api_v1_grocery_list_path(list), headers: headers
      expect(item("milk")["amounts"]).to eq([{"quantity" => 237.0, "unit" => "ml"}])
    end

    it "defaults to the current week and no name" do
      plan(recipe_with(["onion", 1, "each"]))

      travel_to Time.zone.local(2026, 11, 4, 12) do
        post api_v1_grocery_lists_path, headers: headers, as: :json
      end
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("name" => nil, "start_date" => "2026-11-01", "end_date" => "2026-11-07")
    end

    it "saves an empty list when nothing is planned" do
      create_list
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["sections"]).to eq([])
    end

    it "leaves out meals whose recipe the user can no longer see, and counts them" do
      plan(recipe_with(["truffle", 1, "each"], visibility: :only_me))
      plan(recipe_with(["onion", 1, "each"]), sunday + 1.day)

      list = create_list
      expect(response.parsed_body["unavailable_meals_count"]).to eq(1)
      expect(list.items.pluck(:name)).to eq(["onion"])
    end

    it "rejects invalid dates and names" do
      post api_v1_grocery_lists_path, params: {grocery_list: {start_date: "2026-11-07", end_date: "2026-11-01"}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("dates")

      post api_v1_grocery_lists_path, params: {grocery_list: week.merge(name: "x" * 61)}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to have_key("name")
      expect(GroceryList.count).to eq(0)
    end
  end

  describe "GET /api/v1/grocery_lists/:id" do
    it "is a snapshot: later plan changes don't change it" do
      meal = plan(recipe_with(["onion", 1, "each"]))
      list = create_list
      meal.update!(servings: 8)
      plan(recipe_with(["leek", 1, "each"]), sunday + 1.day)

      get api_v1_grocery_list_path(list), headers: headers
      expect(items.map { |i| [i["name"], i["amounts"]] }).to eq([["onion", [{"quantity" => 1.0, "unit" => "each"}]]])
      expect(response.parsed_body).not_to have_key("unavailable_meals_count")
    end

    it "only names recipes the reader can still see" do
      recipe = recipe_with(["onion", 1, "each"])
      plan(recipe)
      list = create_list
      recipe.update!(visibility: :only_me)

      get api_v1_grocery_list_path(list), headers: headers
      expect(item("onion")["recipes"]).to eq([])

      recipe.update!(visibility: :public)
      recipe.user.deactivate!
      get api_v1_grocery_list_path(list), headers: headers
      expect(item("onion")["recipes"]).to eq([])
    end

    it "only finds the user's own household's lists" do
      other = create(:user).household.grocery_lists.create!(start_date: sunday, end_date: sunday)
      get api_v1_grocery_list_path(other), headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/grocery_lists" do
    it "lists the household's lists, newest first, with counts" do
      plan(recipe_with(["onion", 1, "each"], ["leek", 1, "each"]))
      older = create_list(name: "Older")
      older.items.find_by!(name: "leek").update!(status: :have)
      newer = create_list(name: "Newer")
      create(:user).household.grocery_lists.create!(start_date: sunday, end_date: sunday)

      get api_v1_grocery_lists_path, headers: headers

      lists = response.parsed_body["grocery_lists"]
      expect(lists.map { |l| l["id"] }).to eq([newer.id, older.id])
      expect(lists.last).to include("name" => "Older", "items_count" => 2, "to_buy_count" => 1)
      expect(response.parsed_body).to have_key("next_page")
    end
  end

  describe "PATCH /api/v1/grocery_lists/:id/items/:item_id" do
    let(:list) do
      plan(recipe_with(["onion", 1, "each"]))
      create_list
    end
    let(:onion) { list.items.find_by!(name: "onion") }

    it "sets the item's status" do
      %w[bought have to_buy].each do |status|
        patch api_v1_grocery_list_item_path(list, onion), params: {item: {status: status}}, headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include("id" => onion.id, "status" => status, "category" => "produce")
        expect(onion.reload.status).to eq(status)
      end
    end

    it "rejects unknown statuses" do
      patch api_v1_grocery_list_item_path(list, onion), params: {item: {status: "lost"}}, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(onion.reload.status).to eq("to_buy")
    end

    it "only changes items on the user's own household's lists" do
      other_user = create(:user)
      patch api_v1_grocery_list_item_path(list, onion), params: {item: {status: "bought"}},
        headers: {Authorization: "Bearer #{create(:session, user: other_user).token}"}, as: :json
      expect(response).to have_http_status(:not_found)
      expect(onion.reload.status).to eq("to_buy")
    end
  end

  describe "DELETE /api/v1/grocery_lists/:id" do
    it "deletes the list and its items" do
      plan(recipe_with(["onion", 1, "each"]))
      list = create_list

      delete api_v1_grocery_list_path(list), headers: headers
      expect(response).to have_http_status(:no_content)
      expect(GroceryList.exists?(list.id)).to be(false)
      expect(GroceryListItem.where(grocery_list_id: list.id)).to be_empty
    end

    it "can't delete another household's list" do
      other = create(:user).household.grocery_lists.create!(start_date: sunday, end_date: sunday)
      delete api_v1_grocery_list_path(other), headers: headers
      expect(response).to have_http_status(:not_found)
      expect(GroceryList.exists?(other.id)).to be(true)
    end
  end

  it "deletes a household's lists with the household" do
    plan(recipe_with(["onion", 1, "each"]))
    list = create_list
    household.destroy!
    expect(GroceryList.exists?(list.id)).to be(false)
  end
end
