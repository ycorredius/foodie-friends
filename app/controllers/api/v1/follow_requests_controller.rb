# Pending requests to follow the current user, keyed by the requester's user id.
class Api::V1::FollowRequestsController < Api::V1::BaseController
  def index
    requests = paginate(Current.user.follows_received.pending.joins(:follower).merge(User.active).includes(:follower))
    @users = requests.map(&:follower)
    render "api/v1/users/index"
  end

  def approve
    pending_request.accept!
    head :no_content
  end

  # Declines the request.
  def destroy
    pending_request.destroy!
    head :no_content
  end

  private

  def pending_request
    Current.user.follows_received.pending.find_by!(follower_id: params[:id])
  end
end
