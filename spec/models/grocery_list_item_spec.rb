require "rails_helper"

RSpec.describe GroceryListItem, type: :model do
  let(:list) { create(:user).household.grocery_lists.create!(start_date: Date.current, end_date: Date.current) }
  let!(:milk) { Ingredient.create!(name: "milk", category: :dairy_eggs) }

  def manual_item(**attributes)
    list.items.create!(manual: true, **attributes)
  end

  describe "manual items" do
    it "links a catalog ingredient whose name matches, and takes its category" do
      item = manual_item(name: "  MILK ")

      expect(item.ingredient).to eq(milk)
      expect(item.category).to eq("dairy_eggs")
    end

    it "keeps the name as typed, tidied" do
      expect(manual_item(name: "  Paper   towels ").name).to eq("Paper towels")
    end

    it "never adds to the catalog" do
      item = nil
      expect { item = manual_item(name: "paper towels") }.not_to change(Ingredient, :count)
      expect(item.ingredient).to be_nil
      expect(item.category).to eq("other")
    end

    it "uses the category given over the ingredient's" do
      expect(manual_item(name: "milk", category: "beverages").category).to eq("beverages")
      expect(manual_item(name: "milk", category: "other").category).to eq("other")
    end

    it "stores the amount like a generated item's: grams, millilitres or count units" do
      expect(manual_item(name: "milk", quantity: 1, unit: "Gallon").amounts).to eq([Unit::Amount.new(BigDecimal("3785.411784"), "ml")])
      expect(manual_item(name: "limes", quantity: 3, unit: "each").amounts).to eq([Unit::Amount.new(3, "each")])
      expect(manual_item(name: "bananas", quantity: "6").amounts).to eq([Unit::Amount.new(6, nil)])
      expect(manual_item(name: "paper towels").amounts).to eq([])
    end

    it "validates the amount like a recipe line" do
      expect(list.items.new(manual: true, name: "flour", unit: "cup")).not_to be_valid
      expect(list.items.new(manual: true, name: "flour", quantity: 2, unit: "handful")).not_to be_valid
      expect(list.items.new(manual: true, name: "flour", quantity: 0)).not_to be_valid
      expect(list.items.new(manual: true, name: "flour", quantity: -1, unit: "cup")).not_to be_valid
      expect(list.items.new(manual: true, name: " ")).not_to be_valid
    end

    it "can sit beside a generated item for the same ingredient, and beside another manual one" do
      list.items.create!(ingredient: milk, name: "milk", category: :dairy_eggs)

      expect { 2.times { manual_item(name: "milk") } }.to change(list.items, :count).by(2)
      expect { list.items.create!(ingredient: milk, name: "milk", category: :dairy_eggs) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  it "sorts each section by name regardless of case" do
    items = [list.items.new(name: "milk", category: :dairy_eggs), list.items.new(name: "Butter", category: :dairy_eggs)]
    expect(described_class.sections(items)).to eq([["dairy_eggs", items.reverse]])
  end
end
