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
    User.find_or_create_by!(email_address: "demo@example.com") do |user|
      user.first_name = "Demo"
      user.last_name = "User"
      user.password = "password123"
    end
    puts "Development login: demo@example.com / password123"
  end
end
