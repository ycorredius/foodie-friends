# GET /api/v1/users/:user_id/following. Private profiles' lists are only
# visible to their approved followers.
class Api::V1::FollowingController < Api::V1::BaseController
  def index
    user = User.active.find(params[:user_id])
    return render_private_profile unless user.content_visible_to?(Current.user)

    follows = paginate(user.follows_given.accepted.joins(:followed).merge(User.active).includes(:followed))
    @users = follows.map(&:followed)
    render "api/v1/users/index"
  end
end
