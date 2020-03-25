class Organization < ApplicationRecord
  belongs_to :profile
  belongs_to :invoicing_profile
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  validates :name, presence: true
  validates :address, presence: true
end
