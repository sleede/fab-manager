class AddCouponToInvoice < ActiveRecord::Migration
  def change
    add_reference :invoices, :coupon, index: true, foreign_key: true
  end
end
