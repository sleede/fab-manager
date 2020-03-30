# frozen_string_literal:true

class AddCouponToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_reference :invoices, :coupon, index: true, foreign_key: true
  end
end
