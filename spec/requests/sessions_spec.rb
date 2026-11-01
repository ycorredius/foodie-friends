require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  def sign_in(password: "password123")
    post session_path, params: {email_address: user.email_address, password: password}
  end

  it "redirects to sign in when unauthenticated" do
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "signs in with valid credentials" do
    sign_in
    expect(response).to redirect_to(root_url)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.email_address)
  end

  it "rejects a wrong password" do
    sign_in(password: "wrong-password")
    expect(response).to redirect_to(new_session_path)
    expect(user.sessions).to be_empty
  end

  it "signs out and destroys the session" do
    sign_in
    expect { delete session_path }.to change(Session, :count).by(-1)
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "rejects an expired session" do
    sign_in
    user.sessions.update_all(expires_at: 1.second.ago)
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "reactivates a deactivated account on sign-in" do
    user.deactivate!
    sign_in
    expect(response).to redirect_to(root_url)
    expect(flash[:notice]).to eq("Welcome back! Your account has been reactivated.")
    expect(user.reload).not_to be_deactivated
  end
end
