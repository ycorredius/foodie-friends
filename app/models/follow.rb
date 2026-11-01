# A follower following another user. Following a private profile starts as a
# pending request that the followed user approves (accepted) or declines
# (destroyed). Following a public profile is accepted immediately.
class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  enum :status, {pending: 0, accepted: 1}

  validates :followed_id, uniqueness: {scope: :follower_id}
  validate :not_following_self

  def accept!
    update!(status: :accepted)
  end

  private

  def not_following_self
    errors.add(:followed, "can't be yourself") if follower_id == followed_id
  end
end
