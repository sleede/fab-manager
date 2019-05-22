class InvoicingProfile < ActiveRecord::Base
  belongs_to :user
  has_one :address, as: :placeable, dependent: :destroy
  has_one :organization, dependent: :destroy
end
