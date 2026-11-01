# Saving (POST) and unsaving (DELETE) a recipe for the current user.
class Api::V1::SavesController < Api::V1::BaseController
  # Only recipes the user can see can be saved. Saving twice is harmless.
  def create
    recipe = Recipe.visible_to(Current.user).find(params[:recipe_id])
    saved = Current.user.saved_recipes.find_or_create_by!(recipe: recipe)
    render json: {saved: true, saves_count: recipe.reload.saves_count}, status: saved.previously_new_record? ? :created : :ok
  end

  # Works even if the recipe has since become hidden from the user.
  def destroy
    Current.user.saved_recipes.where(recipe_id: params[:recipe_id]).destroy_all
    head :no_content
  end
end
