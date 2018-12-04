class CustomAsset < ActiveRecord::Base
  has_one :custom_asset_file, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :custom_asset_file, allow_destroy: true

  # static method to retrieve the attachment URL of the custom asset
  def self.get_url(name)
    asset = CustomAsset.find_by(name: name)
    asset&.custom_asset_file&.attachment_url
  end

  after_update :update_stylesheet if :viewable_changed?

  def update_stylesheet
    Stylesheet.first.rebuild! if %w[profile-image-file].include? name
  end
end
