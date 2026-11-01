json.extract! @household, :id, :name, :size
json.members @household.members, partial: "api/v1/users/summary", as: :user
