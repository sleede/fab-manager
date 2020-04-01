# frozen_string_literal: true

# UserAvatar is the profile picture for an User
class UserAvatar < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProfilImageUploader
end
