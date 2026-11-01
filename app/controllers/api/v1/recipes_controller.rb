class Api::V1::RecipesController < Api::BaseController
  skip_before_action :authenticate_api_token!, only: %i[show index]
  before_action :authenticate_api_token, only: :show
  before_action :set_recipe, only: :show

  def index
    # TODO: Update this route to only return required information to reduce the about of Kbs being sent. Currently everything including relationships that aren't necessary on initial call.
    recipes = Recipe.search(params[:name]).includes(:recipe_ingredients, :ingredients)
    render json: RecipeSerializer.new(recipes).serializable_hash
  end

  def show
    options = {}
    options[:include] = %i[recipe_ingredients]
    options[:fields] = {recipe: %i[name instructions prep_time cook_time difficulty user_avatar thumbnail_url jumbo_url recipe_ingredients user]}
    render json: RecipeSerializer.new(@recipe, options).serializable_hash.to_json
  end

  private

  # Private recipes are only visible to their owner.
  def set_recipe
    visible = Recipe.where(is_private: false)
    visible = visible.or(Recipe.where(user: @user)) if @user
    @recipe = visible.includes(:recipe_ingredients, :ingredients).find(params[:id])
  end
end
