# POST /api/v1/recipes/:recipe_id/fork copies a recipe the user can see into
# their own recipes, as "only me", so they can adapt it.
class Api::V1::ForksController < Api::V1::BaseController
  def create
    source = Recipe.visible_to(Current.user).includes(recipe_ingredients: :ingredient).find(params[:recipe_id])
    @recipe = source.fork_for(Current.user)
    if @recipe.save
      @servings = @recipe.servings
      render "api/v1/recipes/show", status: :created
    else
      render json: {errors: @recipe.errors}, status: :unprocessable_entity
    end
  end
end
