# Other users' profiles. Deactivated users 404.
class Api::V1::UsersController < Api::V1::BaseController
  # Finds people by name, e.g. to follow them. Requires `q`.
  def index
    query = params[:q].to_s.squish
    return render json: {errors: {q: ["can't be blank"]}}, status: :unprocessable_entity if query.empty?

    pattern = "%#{User.sanitize_sql_like(query)}%"
    @users = paginate(User.active.where("first_name || ' ' || last_name ILIKE ?", pattern))
  end

  def show
    @user = User.active.find(params[:id])
    @follow = Current.user.follows_given.find_by(followed: @user)
  end
end
