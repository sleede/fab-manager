# frozen_string_literal: true

class CreateCouponUsages < ActiveRecord::Migration[7.0]
  def up
    create_table :coupon_usages do |t|
      t.references :object, polymorphic: true
      t.belongs_to :coupon, index: true
      t.integer :count, default: 0
      t.timestamps
    end

    populate_coupon_usages
  end

  def down
    drop_table :coupon_usages
  end

  private

  def populate_coupon_usages
    Coupon.find_each do |coupon|
      count = 0
      coupon.invoices.order(:created_at).each do |invoice|
        count += 1
        invoice.invoice_items.each do |invoice_item|
          if invoice_item.object_type != 'Error' && invoice_item.object
            CouponUsage.create(object: invoice_item.object, coupon: coupon, count: count)
          end
        end
      end
    end
  end
end
