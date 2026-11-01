# Other users' profiles. Deactivated users 404.
class Api::V1::UsersController < Api::V1::BaseController
  def show
    @user = User.active.find(params[:id])
    @follow = Current.user.follows_given.find_by(followed: @user)
  end
end
