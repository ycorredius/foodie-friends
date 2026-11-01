require "rails_helper"

RSpec.describe Recipe, type: :model do
  describe "validations" do
    it "requires a title and servings in range" do
      recipe = build(:recipe, title: "", servings: 0)
      expect(recipe).not_to be_valid
      expect(recipe.errors.attribute_names).to include(:title, :servings)
    end

    it "rejects blank steps" do
      expect(build(:recipe, steps: ["Mix", ""])).not_to be_valid
      expect(build(:recipe, steps: nil)).not_to be_valid
    end

    it "rejects unknown enum values instead of raising" do
      recipe = build(:recipe, meal_type: "brunch", difficulty: "extreme", visibility: "friends")
      expect(recipe).not_to be_valid
      expect(recipe.errors.attribute_names).to include(:meal_type, :difficulty, :visibility)
    end

    it "allows meal type and difficulty to be blank" do
      expect(build(:recipe, meal_type: nil, difficulty: nil)).to be_valid
    end

    it "accepts JPEG, PNG and WebP photos" do
      recipe = build(:recipe)
      recipe.photo.attach(io: file_fixture("photo.png").open, filename: "photo.png", content_type: "image/png")
      expect(recipe).to be_valid
    end

    it "rejects other file types and photos over 10 MB" do
      recipe = build(:recipe)
      recipe.photo.attach(io: StringIO.new("not an image"), filename: "notes.txt", content_type: "text/plain")
      recipe.photo.blob.byte_size = Recipe::PHOTO_MAX_BYTES + 1
      expect(recipe).not_to be_valid
      expect(recipe.errors[:photo]).to contain_exactly("must be a JPEG, PNG or WebP image", "must be 10 MB or smaller")
    end
  end

  describe ".visible_to" do
    it "includes public recipes and the user's own only-me recipes" do
      user = create(:user)
      public_recipe = create(:recipe)
      own_private = create(:recipe, :only_me, user: user)
      create(:recipe, :only_me)

      expect(Recipe.visible_to(user)).to contain_exactly(public_recipe, own_private)
    end

    it "hides public recipes by deactivated users" do
      recipe = create(:recipe)
      recipe.user.deactivate!
      expect(Recipe.visible_to(create(:user))).not_to include(recipe)
    end
  end

  describe "#ingredient_lines=" do
    let(:recipe) { create(:recipe) }

    it "creates ordered lines, reusing catalog ingredients by normalized name" do
      flour = create(:ingredient, name: "flour")
      recipe.update!(ingredient_lines: [
        {name: "  Flour ", quantity: "2", unit: "cup"},
        {name: "Salt", quantity: nil, unit: nil, note: "to taste"}
      ])

      lines = recipe.reload.recipe_ingredients
      expect(lines.map(&:name)).to eq(["flour", "salt"])
      expect(lines.first.ingredient).to eq(flour)
      expect(lines.map(&:position)).to eq([0, 1])
      expect(Ingredient.count).to eq(2)
    end

    it "replaces existing lines" do
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])
      recipe.update!(ingredient_lines: [{name: "sugar", quantity: 2, unit: "tbsp"}])
      expect(recipe.reload.recipe_ingredients.map(&:name)).to eq(["sugar"])
      expect(RecipeIngredient.count).to eq(1)
    end

    it "keeps existing lines when the new lines are invalid" do
      recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])
      expect(recipe.update(ingredient_lines: [{name: "sugar", quantity: 2, unit: "handful"}])).to be(false)
      expect(recipe.errors.attribute_names).to include(:"ingredients[0].unit")
      expect(recipe.reload.recipe_ingredients.map(&:name)).to eq(["flour"])
    end
  end

  describe "#total_minutes" do
    it "adds prep and cook time, or is nil when neither is set" do
      expect(build(:recipe, prep_minutes: 10, cook_minutes: 25).total_minutes).to eq(35)
      expect(build(:recipe, prep_minutes: 10).total_minutes).to eq(10)
      expect(build(:recipe).total_minutes).to be_nil
    end
  end
end
