class ProfileCustomField < ApplicationRecord
  has_many :user_profile_custom_fields
  has_many :invoicing_profiles, through: :user_profile_custom_fields
end
