class Api::V1::FollowersController < Api::V1::BaseController
  # GET /api/v1/users/:user_id/followers. Private profiles' lists are only
  # visible to their approved followers.
  def index
    user = User.active.find(params[:user_id])
    return render_private_profile unless user.content_visible_to?(Current.user)

    follows = paginate(user.follows_received.accepted.joins(:follower).merge(User.active).includes(:follower))
    @users = follows.map(&:follower)
    render "api/v1/users/index"
  end

  # DELETE /api/v1/me/followers/:id removes that user as one of your followers.
  def destroy
    Current.user.follows_received.accepted.find_by!(follower_id: params[:id]).destroy!
    head :no_content
  end
end
