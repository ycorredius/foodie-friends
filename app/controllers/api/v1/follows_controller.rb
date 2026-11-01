# The current user following another user (POST) or unfollowing them /
# cancelling a pending request (DELETE). Following a private profile creates a
# pending request.
class Api::V1::FollowsController < Api::V1::BaseController
  def create
    user = User.active.find(params[:user_id])
    if user == Current.user
      return render json: {errors: {user: ["can't be yourself"]}}, status: :unprocessable_entity
    end

    follow = Current.user.follow(user)
    render json: {status: follow.status}, status: follow.previously_new_record? ? :created : :ok
  end

  def destroy
    Current.user.unfollow(User.find(params[:user_id]))
    head :no_content
  end
end
