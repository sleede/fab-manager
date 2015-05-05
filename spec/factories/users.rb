FactoryGirl.define do
  sequence(:email) { |n| "member#{n}@sleede.com" }
  sequence(:username) { |n| "member#{n}" }

  factory :user do
    email { FactoryGirl.generate :email }
    username { FactoryGirl.generate :username }
    password 'sleede22'
    password_confirmation 'sleede22'
    association :profile, strategy: :build
    group { Group.first }
  end

end
