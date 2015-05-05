FactoryGirl.define do
  sequence(:name) { |n| "project#{n}" }

  factory :project do
    name { FactoryGirl.generate :name }
    description { Faker::Lorem.paragraph }
  end
end
