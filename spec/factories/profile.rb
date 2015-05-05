FactoryGirl.define do
  sequence(:last_name) { |n| n }

  factory :profile do
    first_name 'member'
    last_name { FactoryGirl.generate :last_name }
    gender true
    birthday { 30.years.ago }
    phone '0606060606'
  end
end
