json.partial! "api/v1/users/summary", user: @user
json.followers_count @user.followers.merge(User.active).count
json.following_count @user.following.merge(User.active).count
json.recipes_count Recipe.visible_to(Current.user).where(user: @user).count
# "accepted", "pending" (a request awaiting approval), or null.
json.follow_status @follow&.status
json.follows_you @user.following?(Current.user)
