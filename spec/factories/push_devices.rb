FactoryBot.define do
  factory :session do
    user
  end

  factory :push_device, class: "ApplicationPushDevice" do
    owner { association(:session) }
    platform { :google }
    sequence(:token) { |n| "fcm-token-#{n}" }
    name { "Pixel" }
  end
end
