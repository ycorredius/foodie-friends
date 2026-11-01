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
end
