FactoryBot.define do
  # The plaintext token is only available on the created instance, via #token.
  factory :session do
    user
  end
end
