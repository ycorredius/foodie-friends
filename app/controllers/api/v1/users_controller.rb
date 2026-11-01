class Api::V1::UsersController < Api::BaseController
  skip_before_action :authenticate_api_token!, only: [:create]
  before_action :configure_permitted_parameters, only: [:create]

  def create
    user = User.new(devise_parameter_sanitizer.sanitize(:sign_up))
    if user.save
      api_token = user.api_tokens.create!
      render json: {token: api_token.token, user: UserSerializer.new(user, root: false)}, status: :created
    else
      render json: {
        errors: user.errors,
        error: user.errors.full_messages.to_sentence
      }, status: :unprocessable_entity
    end
  end

  private

  def devise_parameter_sanitizer
    @devise_parameter_sanitizer ||= Devise::ParameterSanitizer.new(User, :user, params)
  end
end
