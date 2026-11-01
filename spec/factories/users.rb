FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    password { "password123" }
  end
end
