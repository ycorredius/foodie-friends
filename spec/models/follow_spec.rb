require "rails_helper"

RSpec.describe Follow, type: :model do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:private_carol) { create(:user, private_profile: true) }

  describe "User#follow" do
    it "accepts immediately for a public profile" do
      expect(alice.follow(bob)).to be_accepted
      expect(alice).to be_following(bob)
      expect(bob.followers).to contain_exactly(alice)
    end

    it "creates a pending request for a private profile" do
      expect(alice.follow(private_carol)).to be_pending
      expect(alice).not_to be_following(private_carol)
      expect(private_carol.followers).to be_empty
    end

    it "returns the existing follow when following twice" do
      first = alice.follow(bob)
      expect(alice.follow(bob)).to eq(first)
      expect(Follow.count).to eq(1)
    end

    it "can't follow yourself" do
      expect { alice.follow(alice) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  it "unfollows and cancels pending requests" do
    alice.follow(bob)
    alice.follow(private_carol)
    alice.unfollow(bob)
    alice.unfollow(private_carol)
    expect(Follow.count).to eq(0)
  end

  it "approves pending requests when a profile becomes public, and keeps followers when it becomes private" do
    alice.follow(private_carol)
    private_carol.update!(private_profile: false)
    expect(alice).to be_following(private_carol)

    private_carol.update!(private_profile: true)
    expect(alice).to be_following(private_carol)
  end

  it "is deleted with either user" do
    alice.follow(bob)
    bob.destroy
    expect(Follow.count).to eq(0)
  end
end
