# frozen_string_literal: true

# UserProfileCustomField store values for custom fields per user's profile
class UserProfileCustomField < ApplicationRecord
  belongs_to :invoicing_profile
  belongs_to :profile_custom_field
end
