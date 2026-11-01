require "rails_helper"

RSpec.describe Session, type: :model do
  let(:session) { create(:session) }

  it "stores only a digest of its token" do
    expect(session.token).to be_present
    expect(session.token_digest).to eq(Session.digest(session.token))
    expect(Session.find(session.id).token).to be_nil
  end

  it "expires after the TTL" do
    expect(session.expires_at).to be_within(1.minute).of(Session::TTL.from_now)
  end

  describe ".find_by_token" do
    it "finds an active session" do
      expect(Session.find_by_token(session.token)).to eq(session)
    end

    it "ignores expired sessions" do
      session.update_columns(expires_at: 1.second.ago)
      expect(Session.find_by_token(session.token)).to be_nil
    end

    it "ignores unknown, blank and digest tokens" do
      expect(Session.find_by_token("nope")).to be_nil
      expect(Session.find_by_token("")).to be_nil
      expect(Session.find_by_token(nil)).to be_nil
      expect(Session.find_by_token(session.token_digest)).to be_nil
    end
  end

  describe "#extend_expiry" do
    it "slides the expiry forward" do
      session.update_columns(expires_at: 1.day.from_now)
      session.extend_expiry
      expect(session.reload.expires_at).to be_within(1.minute).of(Session::TTL.from_now)
    end

    it "skips the write when recently extended" do
      session.update_columns(expires_at: Session::TTL.from_now - 1.minute)
      expect { session.extend_expiry }.not_to change { session.reload.updated_at }
    end
  end
end
