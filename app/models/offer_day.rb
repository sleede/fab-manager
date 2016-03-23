class OfferDay < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  has_many :invoices, as: :invoiced, dependent: :destroy
  belongs_to :subscription
end
