FactoryBot.define do
  # A place reserved by an invitation (ADR 0019). The token is on the instance: invitation.token.
  factory :invitation do
    household_member do
      association(:household_member, strategy: :build, user: nil, role: :member, invitation: instance)
    end
    created_by { association(:user) }
    sequence(:email) { |n| "invite#{n}@example.com" }
    after(:build, &:renew_token)
  end
end
