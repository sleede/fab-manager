class InvoicingProfile < ActiveRecord::Base
  belongs_to :user
  has_one :address, as: :placeable, dependent: :destroy
  has_one :organization, dependent: :destroy
  has_many :invoices, dependent: :destroy


  def full_name
    # if first_name or last_name is nil, the empty string will be used as a temporary replacement
    (first_name || '').humanize.titleize + ' ' + (last_name || '').humanize.titleize
  end
end
