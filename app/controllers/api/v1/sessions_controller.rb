class Api::V1::SessionsController < Api::V1::BaseController
  allow_unauthenticated_access only: :create
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rate_limited }

  # Issues a new session token for each sign-in. Signing in reactivates a
  # deactivated account; the response's `reactivated` says when that happened.
  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      @reactivated = user.reactivate
      start_new_session_for user
      render :create, status: :created
    else
      render json: {error: "Invalid email address or password."}, status: :unauthorized
    end
  end

  # Revokes the token used for this request.
  def destroy
    Current.session.destroy
    head :no_content
  end
end
