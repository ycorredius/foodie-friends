json.token Current.session.token
json.reactivated @reactivated.present?
json.user do
  json.partial! "api/v1/users/user", user: Current.user
end
