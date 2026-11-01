FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "ingredient #{n}" }
  end

  factory :recipe do
    user
    sequence(:title) { |n| "Recipe #{n}" }
    servings { 4 }
    steps { ["Mix everything.", "Bake for 20 minutes."] }

    trait :only_me do
      visibility { :only_me }
    end
  end

  factory :recipe_ingredient do
    recipe
    ingredient
    quantity { 1 }
    unit { "cup" }
  end
end
