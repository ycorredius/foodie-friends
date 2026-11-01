class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  prepend_before_action :authenticate_api_token!

  private

  def authenticate_api_token!
    head :unauthorized unless authenticate_api_token
  end

  # Signs in the user for a valid "Authorization: Bearer <token>" header.
  # Use directly as a before_action for endpoints where auth is optional.
  def authenticate_api_token
    @api_token = authenticate_with_http_token { |token, _options| ApiToken.authenticate(token) }
    return unless @api_token

    @user = @api_token.user
    # API requests aren't logins; don't update Devise's sign-in tracking.
    request.env["devise.skip_trackable"] = true
    sign_in(@user, store: false)
  end
end
