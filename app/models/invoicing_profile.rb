class InvoicingProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :address
  belongs_to :organization
end
