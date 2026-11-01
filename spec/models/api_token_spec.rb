# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  expires_at   :datetime         not null
#  last_used_at :datetime
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_token_digest  (token_digest) UNIQUE
#  index_api_tokens_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe ApiToken, type: :model do
  let(:api_token) { create(:api_token) }

  describe "creation" do
    it "stores only a digest of the token" do
      expect(api_token.token).to be_present
      expect(api_token.token_digest).to eq(ApiToken.digest(api_token.token))
      expect(ApiToken.find(api_token.id).token).to be_nil
    end

    it "expires after the TTL" do
      expect(api_token.expires_at).to be_within(1.minute).of(ApiToken::TTL.from_now)
    end
  end

  describe ".authenticate" do
    it "returns the token for a valid plaintext token" do
      expect(ApiToken.authenticate(api_token.token)).to eq(api_token)
    end

    it "slides the expiry forward and records use" do
      api_token.update_columns(expires_at: 1.day.from_now, last_used_at: nil)
      ApiToken.authenticate(api_token.token)
      api_token.reload
      expect(api_token.expires_at).to be_within(1.minute).of(ApiToken::TTL.from_now)
      expect(api_token.last_used_at).to be_present
    end

    it "rejects expired tokens" do
      api_token.update_columns(expires_at: 1.second.ago)
      expect(ApiToken.authenticate(api_token.token)).to be_nil
    end

    it "rejects unknown and blank tokens" do
      expect(ApiToken.authenticate("nope")).to be_nil
      expect(ApiToken.authenticate("")).to be_nil
      expect(ApiToken.authenticate(nil)).to be_nil
    end

    it "rejects the stored digest itself" do
      expect(ApiToken.authenticate(api_token.token_digest)).to be_nil
    end
  end
end
