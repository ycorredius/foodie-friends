require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes the email address" do
    user = create(:user, email_address: "  Someone@Example.COM ")
    expect(user.email_address).to eq("someone@example.com")
  end

  it "requires a unique email address" do
    create(:user, email_address: "taken@example.com")
    user = build(:user, email_address: "TAKEN@example.com")
    expect(user).not_to be_valid
    expect(user.errors[:email_address]).to be_present
  end

  it "rejects malformed email addresses" do
    expect(build(:user, email_address: "not-an-email")).not_to be_valid
  end

  it "requires first and last names" do
    user = build(:user, first_name: "", last_name: "")
    expect(user).not_to be_valid
    expect(user.errors.attribute_names).to include(:first_name, :last_name)
  end

  it "requires passwords of at least 8 characters" do
    expect(build(:user, password: "short")).not_to be_valid
  end

  it "destroys its sessions" do
    user = create(:user)
    create(:session, user: user)
    expect { user.destroy }.to change(Session, :count).by(-1)
  end

  describe "deactivation" do
    let(:user) { create(:user) }

    it "deactivates and signs out everywhere" do
      create_list(:session, 2, user: user)
      freeze_time do
        user.deactivate!
        expect(user).to be_deactivated
        expect(user.deletes_at).to eq(User::DELETION_GRACE_PERIOD.from_now)
      end
      expect(user.sessions.reload).to be_empty
    end

    it "reactivates, reporting whether anything changed" do
      user.deactivate!
      expect(user.reactivate).to be(true)
      expect(user.reload).not_to be_deactivated
      expect(user.reactivate).to be(false)
    end

    it "is due for deletion only after the grace period" do
      recent = create(:user, deactivated_at: (User::DELETION_GRACE_PERIOD - 1.day).ago)
      expired = create(:user, deactivated_at: (User::DELETION_GRACE_PERIOD + 1.day).ago)
      expect(User.due_for_deletion).to contain_exactly(expired)
      expect(User.active).to contain_exactly(user)
      expect(recent).to be_deactivated
    end
  end
end
