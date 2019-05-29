class InvoicingProfile < ActiveRecord::Base
  belongs_to :user
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true
  has_one :organization, dependent: :destroy
  accepts_nested_attributes_for :organization, allow_destroy: false
  has_many :invoices, dependent: :destroy


  def full_name
    # if first_name or last_name is nil, the empty string will be used as a temporary replacement
    (first_name || '').humanize.titleize + ' ' + (last_name || '').humanize.titleize
  end
end
