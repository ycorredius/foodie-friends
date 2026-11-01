require "rails_helper"

RSpec.describe SavedRecipe, type: :model do
  let(:recipe) { create(:recipe) }

  it "keeps the recipe's saves_count up to date" do
    saves = create_list(:user, 2).map { |user| user.saved_recipes.create!(recipe: recipe) }
    expect(recipe.reload.saves_count).to eq(2)
    saves.first.destroy
    expect(recipe.reload.saves_count).to eq(1)
  end

  it "allows each user to save a recipe once" do
    user = create(:user)
    user.saved_recipes.create!(recipe: recipe)
    expect(user.saved_recipes.build(recipe: recipe)).not_to be_valid
  end

  describe "Recipe.by_popularity" do
    let!(:older) { create(:recipe) }
    let!(:newer) { create(:recipe) }
    let(:savers) { create_list(:user, 3) }

    it "orders all-time by saves, newest first among ties" do
      savers.first(2).each { |user| user.saved_recipes.create!(recipe: older) }
      untouched = create(:recipe)
      expect(Recipe.by_popularity.to_a).to eq([older, untouched, newer])
      expect(untouched.id).to be > newer.id
    end

    it "counts only saves within a period" do
      savers.each { |user| user.saved_recipes.create!(recipe: older, created_at: 2.weeks.ago) }
      savers.first.saved_recipes.create!(recipe: newer)

      expect(Recipe.by_popularity(1.week).to_a).to eq([newer, older])
      expect(Recipe.by_popularity.to_a).to eq([older, newer])
    end
  end

  describe "Recipe#fork_for" do
    it "copies the recipe as an only-me draft linked to the original" do
      original = create(:recipe, title: "Chili", tags: ["budget"], meal_type: :dinner, prep_minutes: 10)
      original.update!(ingredient_lines: [{name: "beans", quantity: 2, unit: "can", note: "drained"}])
      original.photo.attach(io: file_fixture("photo.png").open, filename: "photo.png", content_type: "image/png")
      user = create(:user)

      fork = original.fork_for(user)
      fork.save!

      expect(fork).to have_attributes(user: user, title: "Chili", tags: ["budget"], meal_type: "dinner",
        prep_minutes: 10, forked_from: original)
      expect(fork).to be_visibility_only_me
      expect(fork.recipe_ingredients.map { |l| [l.name, l.quantity, l.unit, l.note] }).to eq([["beans", 2, "can", "drained"]])
      expect(fork.photo).not_to be_attached
      expect(original.reload.recipe_ingredients.count).to eq(1)
    end

    it "keeps the fork when the original is deleted" do
      original = create(:recipe)
      fork = original.fork_for(create(:user)).tap(&:save!)
      original.destroy
      expect(fork.reload.forked_from).to be_nil
    end
  end
end
