class Api::V1::MeController < Api::V1::BaseController
  rate_limit to: 5, within: 3.minutes, only: :destroy, with: -> { render_rate_limited }

  def show
  end

  def update
    if Current.user.update(params.expect(user: [:first_name, :last_name, :unit_system]))
      render :show
    else
      render json: {errors: Current.user.errors}, status: :unprocessable_entity
    end
  end

  # Deactivates the account (requires the password). Signing in again before
  # deletes_at reactivates it; after that it's deleted permanently.
  def destroy
    if Current.user.authenticate(params[:password].to_s)
      Current.user.deactivate!
      render json: {deletes_at: Current.user.deletes_at}
    else
      render json: {errors: {password: ["is incorrect"]}}, status: :unprocessable_entity
    end
  end
end
