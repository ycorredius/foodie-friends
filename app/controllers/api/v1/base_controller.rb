# Base for the JSON API used by the mobile client. Authenticates with a
# session token sent as "Authorization: Bearer <token>" instead of a cookie.
class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :require_authentication

  def self.allow_unauthenticated_access(**options)
    skip_before_action :require_authentication, **options
  end

  private

  def require_authentication
    resume_session || render(json: {error: "Unauthorized"}, status: :unauthorized)
  end

  def resume_session
    Current.session ||= authenticate_with_http_token { |token, _options| Session.find_by_token(token)&.extend_expiry }
  end

  def start_new_session_for(user)
    Current.session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
  end

  def render_rate_limited
    render json: {error: "Too many attempts. Try again later."}, status: :too_many_requests
  end
end
