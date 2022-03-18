class UserProfileCustomField < ApplicationRecord
  belongs_to :invoicing_profile
  belongs_to :profile_custom_field
end
