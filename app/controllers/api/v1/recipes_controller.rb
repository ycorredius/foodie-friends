class Api::V1::RecipesController < Api::V1::BaseController
  PAGE_SIZE = 20
  MAX_PAGE_SIZE = 50

  before_action :set_own_recipe, only: %i[update destroy]

  # Recipes visible to the current user, newest first. Paginate by passing the
  # response's next_cursor as `before`. Filter to one author with `user_id`.
  def index
    scope = Recipe.visible_to(Current.user).includes(:user).order(id: :desc)
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(id: ...params[:before].to_i) if params[:before].present?

    limit = params.fetch(:limit, PAGE_SIZE).to_i.clamp(1, MAX_PAGE_SIZE)
    recipes = scope.limit(limit + 1).to_a
    @next_cursor = recipes[limit - 1].id if recipes.size > limit
    @recipes = recipes.first(limit)
  end

  # Pass `servings` to scale ingredient quantities.
  def show
    @recipe = Recipe.visible_to(Current.user).includes(:user, recipe_ingredients: :ingredient).find(params[:id])
    @servings = requested_servings || @recipe.servings
  end

  def create
    @recipe = Current.user.recipes.new(recipe_params)
    if @recipe.save
      @servings = @recipe.servings
      render :show, status: :created
    else
      render_errors
    end
  end

  # Sending `ingredients` replaces all of the recipe's ingredient lines.
  def update
    if @recipe.update(recipe_params)
      @servings = @recipe.servings
      render :show
    else
      render_errors
    end
  end

  def destroy
    @recipe.destroy
    head :no_content
  end

  private

  def set_own_recipe
    @recipe = Current.user.recipes.find(params[:id])
  end

  def recipe_params
    attributes = params.expect(recipe: [
      :title, :description, :servings, :prep_minutes, :cook_minutes, :meal_type, :difficulty, :visibility,
      steps: [], ingredients: [[:name, :quantity, :unit, :note]]
    ])
    attributes[:ingredient_lines] = attributes.delete(:ingredients) if attributes.key?(:ingredients)
    attributes
  end

  # Invalid values are ignored; out-of-range values are clamped to what a recipe allows.
  def requested_servings
    Integer(params[:servings], exception: false)&.clamp(1, 100) if params[:servings].present?
  end

  def render_errors
    render json: {errors: @recipe.errors}, status: :unprocessable_entity
  end
end
