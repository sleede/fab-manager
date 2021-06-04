# frozen_string_literal: true

require 'integrity/archive_helper'

# Previously, the relation between an invoice and the bought objects where stored disparately:
# Invoice.invoiced_id & Invoice.invoiced_type saved the main object, and if a subscription was took at the same time of
# a reservation (the only case where two object were bought at the same time), the reservation was saved in
# Invoice.invoiced and the subscription was saved in InvoiceItem.subscription_id
#
# From this migration, everything will be saved in InvoiceItems.object_id & InvoiceItem.object_type. This will be more
# extensible and will allow to invoice more types of objects  the future.
class AddObjectToInvoiceItem < ActiveRecord::Migration[5.2]
  def up
    # first check that there's no bogus invoices
    raise InvalidInvoiceError if Invoice.where(invoiced_id: nil).where.not(invoiced_type: 'Error').count.positive?

    # check the footprints
    Integrity::ArchiveHelper.check_footprints

    # if everything is ok, proceed with migration: remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    add_reference :invoice_items, :object, polymorphic: true
    add_column :invoice_items, :main, :boolean
    # migrate data
    Invoice.where.not(invoiced_type: 'Reservation').each do |invoice|
      execute %(
        UPDATE invoice_items
        SET object_id = #{invoice.invoiced_id || 'NULL'},
            object_type = '#{invoice.invoiced_type}',
            main = true
        WHERE id = #{invoice.invoice_items.first.id}
      )
    end
    Invoice.where(invoiced_type: 'Reservation').each do |invoice|
      execute %(
        UPDATE invoice_items
        SET object_id = #{invoice.invoiced_id || 'NULL'},
            object_type = '#{invoice.invoiced_type}',
            main = true
        WHERE id = #{invoice.invoice_items.where(subscription_id: nil).first.id}
      )
      invoice.invoice_items.where(subscription_id: nil)[1..-1].each do |ii|
        execute %(
          UPDATE invoice_items
          SET object_id = #{invoice.invoiced_id || 'NULL'},
              object_type = '#{invoice.invoiced_type}'
          WHERE id = #{ii.id}
        )
      end
      subscription_item = invoice.invoice_items.where.not(subscription_id: nil).first
      next unless subscription_item

      execute %(
        UPDATE invoice_items
        SET object_id = #{subscription_item.subscription_id || 'NULL'},
            object_type = 'Subscription'
        WHERE id = #{subscription_item.id}
      )
    end

    execute %(
        UPDATE invoices
        SET payment_method = 'card'
        WHERE payment_method ='stripe'
    )
    remove_column :invoice_items, :subscription_id
    remove_reference :invoices, :invoiced, polymorphic: true

    # chain records
    puts 'Chaining all record. This may take a while...'
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end

  def down
    # first, check the footprints
    Integrity::ArchiveHelper.check_footprints

    # if everything is ok, proceed with migration: remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    add_column :invoice_items, :subscription_id, :integer
    add_reference :invoices, :invoiced, polymorphic: true
    # migrate data
    InvoiceItem.where(main: true).each do |ii|
      execute %(
        UPDATE invoices
        SET invoiced_id = #{ii.object_id || 'NULL'},
            invoiced_type = '#{ii.object_type}'
        WHERE id = #{ii.invoice.id}
      )
    end
    InvoiceItem.where(object_type: 'Subscription').each do |ii|
      execute %(
        UPDATE invoice_items
        SET subscription_id = #{ii.object_id || 'NULL'}
        WHERE id = #{ii.id}
      )
    end

    execute %(
        UPDATE invoices
        SET payment_method = 'stripe'
        WHERE payment_method ='card'
    )
    remove_column :invoice_items, :main
    remove_reference :invoice_items, :object, polymorphic: true

    # chain records
    puts 'Chaining all record. This may take a while...'
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end
end
