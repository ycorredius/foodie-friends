# GET /api/v1/me/saved_recipes: the current user's saved recipes, most
# recently saved first. Recipes that have become hidden from them are left out.
class Api::V1::SavedRecipesController < Api::V1::BaseController
  def index
    saves = paginate(
      Current.user.saved_recipes
        .where(recipe_id: Recipe.visible_to(Current.user).select(:id))
        .includes(recipe: [:user, {photo_attachment: :blob}])
    )
    @recipes = saves.map(&:recipe)
    render "api/v1/recipes/index"
  end
end
