json.users @users, partial: "api/v1/users/summary", as: :user
json.next_page @pagy.next
