# frozen_string_literal: true

# ProfileCustomFields are customer fields, configured by an admin, added to the user's profile
class ProfileCustomField < ApplicationRecord
  has_many :user_profile_custom_fields, dependent: :destroy
  has_many :invoicing_profiles, through: :user_profile_custom_fields
end
