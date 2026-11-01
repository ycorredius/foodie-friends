class Api::V1::AuthsController < Api::BaseController
  skip_before_action :authenticate_api_token!, only: [:create]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { render json: {error: "Too many login attempts. Try again later."}, status: :too_many_requests }

  def self.dummy_password_digest
    @dummy_password_digest ||= Devise::Encryptor.digest(User, SecureRandom.hex)
  end

  # Requires email and password params.
  # Issues a new API token for each login.
  def create
    if (user = authenticate_user)
      user.api_tokens.expired.delete_all
      api_token = user.api_tokens.create!
      render json: {token: api_token.token, user: UserSerializer.new(user, root: false)}
    else
      render json: {error: error_message}, status: :unauthorized
    end
  end

  # Revokes the token used for this request.
  def destroy
    @api_token.destroy
    head :no_content
  end

  private

  def authenticate_user
    user = User.find_for_authentication(email: params[:email].to_s)
    return user if user&.valid_password?(params[:password])

    # Check a dummy hash when the email is unknown so response time doesn't
    # reveal which emails have accounts.
    User.new(encrypted_password: self.class.dummy_password_digest).valid_password?(params[:password]) unless user
    nil
  end

  def error_message
    keys = User.authentication_keys.join(I18n.translate(:"support.array.words_connector"))
    I18n.t("devise.failure.invalid", authentication_keys: keys)
  end
end
