class Api::V1::RegistrationsController < Api::V1::BaseController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rate_limited }

  def create
    user = User.new(user_params)
    if user.save
      start_new_session_for user
      render "api/v1/sessions/create", status: :created
    else
      render json: {errors: user.errors}, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [:first_name, :last_name, :email_address, :password, :password_confirmation])
  end
end
