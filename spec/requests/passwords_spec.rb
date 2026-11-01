require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }

  it "resets the password and revokes all sessions, including API tokens" do
    create(:session, user: user)
    token = user.password_reset_token

    put password_path(token), params: {password: "new-password", password_confirmation: "new-password"}

    expect(response).to redirect_to(new_session_path)
    expect(user.sessions.reload).to be_empty
    expect(user.reload.authenticate("new-password")).to be_truthy
  end

  it "shows validation errors for a too-short password" do
    token = user.password_reset_token
    put password_path(token), params: {password: "short", password_confirmation: "short"}
    expect(flash[:alert]).to include("too short")
  end
end
