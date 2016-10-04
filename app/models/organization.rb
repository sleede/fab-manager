class Organization < ActiveRecord::Base
  belongs_to :profile
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  validates :name, presence: true
  validates :address, presence: true
end
