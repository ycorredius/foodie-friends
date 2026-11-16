# Idempotent: safe to run repeatedly in any environment, including production
# (bin/rails db:seed). Re-running updates seeded records in place.
seeds = Rails.root.join("db/seeds")

ActiveRecord::Base.transaction do
  # Ingredient catalog with grocery categories. Existing ingredients, including
  # ones users created, get the catalog's category.
  YAML.load_file(seeds.join("ingredients.yml")).each do |category, names|
    names.each { |name| Ingredient.find_or_initialize_by(name: name).update!(category: category) }
  end

  # Starter recipes, owned by an account nobody can sign in to: the address is
  # on the reserved .example domain and the password is random.
  kitchen = User.find_or_create_by!(email_address: "kitchen@foodiefriends.example") do |user|
    user.first_name = "Foodie Friends"
    user.last_name = "Kitchen"
    user.password = SecureRandom.base58(32)
  end

  YAML.load_file(seeds.join("recipes.yml")).each do |attributes|
    recipe = kitchen.recipes.find_or_initialize_by(title: attributes["title"])
    recipe.update!(
      **attributes.except("ingredients").symbolize_keys,
      visibility: :public,
      ingredient_lines: attributes["ingredients"].map(&:symbolize_keys)
    )
  end

  if Rails.env.development?
    demo = User.find_or_create_by!(email_address: "demo@example.com") do |user|
      user.first_name = "Demo"
      user.last_name = "User"
      user.password = "password123"
    end
    puts "Development login: demo@example.com / password123"

    # A planned week for the demo account, so the Plan screen has something to
    # show: this week (per the demo's week start day), filled only while it has
    # no meals, so re-running never undoes changes made in the app. Day 2 (the
    # third day) stays empty on purpose.
    week = demo.week_containing(Date.current)
    meals = demo.household.planned_meals
    if meals.where(date: week).none?
      starter = kitchen.recipes.index_by(&:title)
      [
        [0, :breakfast, "Overnight Oats"],
        [0, :dinner, "Black Bean Chili"],
        [1, :lunch, "Lentil Soup"],
        [1, :dinner, "Sheet Pan Chicken and Vegetables"],
        [3, :dinner, "Spaghetti with Meat Sauce"],
        [4, :lunch, "Tuna Salad Sandwiches"],
        [4, :dinner, "Chicken Fried Rice"],
        [5, :breakfast, "Fluffy Pancakes"],
        [6, :dinner, "Black Bean Chili"]
      ].each do |day, slot, title|
        meals.create!(recipe: starter.fetch(title), date: week.first + day, meal_slot: slot, servings: 4)
      end
      puts "Planned #{week.first}..#{week.last} for the demo account"
    end
  end
end
