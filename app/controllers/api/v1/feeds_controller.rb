# Public recipes from people the current user follows, newest first.
class Api::V1::FeedsController < Api::V1::BaseController
  def show
    @recipes = paginate(Recipe.feed_for(Current.user).includes(:user).with_attached_photo)
    render "api/v1/recipes/index"
  end
end
