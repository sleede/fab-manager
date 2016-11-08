class UserAvatar < Asset
  include ImageValidatorConcern
  mount_uploader :attachment, ProfilImageUploader
end
