json.token Current.session.token
json.user do
  json.partial! "api/v1/users/user", user: Current.user
end
