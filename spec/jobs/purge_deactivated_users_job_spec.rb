require "rails_helper"

RSpec.describe PurgeDeactivatedUsersJob, type: :job do
  it "deletes accounts past the grace period with everything they own" do
    expired = create(:user, deactivated_at: (User::DELETION_GRACE_PERIOD + 1.day).ago)
    recipe = create(:recipe, user: expired)
    recipe.update!(ingredient_lines: [{name: "flour", quantity: 1, unit: "cup"}])

    described_class.perform_now

    expect(User.exists?(expired.id)).to be(false)
    expect(Recipe.exists?(recipe.id)).to be(false)
    expect(RecipeIngredient.count).to eq(0)
    expect(Ingredient.exists?(name: "flour")).to be(true)
  end

  it "keeps active accounts and ones still in the grace period" do
    active = create(:user)
    recent = create(:user, deactivated_at: (User::DELETION_GRACE_PERIOD - 1.day).ago)

    described_class.perform_now

    expect(User.where(id: [active.id, recent.id]).count).to eq(2)
  end

  it "is scheduled to run daily in production" do
    tasks = YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production")
    expect(tasks.values).to include(a_hash_including("class" => "PurgeDeactivatedUsersJob"))
  end
end
