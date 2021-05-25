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
      invoice.invoice_items.first.update_attributes(
        object_id: invoice.invoiced_id,
        object_type: invoice.invoiced_type,
        main: true
      )
    end
    Invoice.where(invoiced_type: 'Reservation').each do |invoice|
      invoice.invoice_items.where(subscription_id: nil).first.update_attributes(
        object_id: invoice.invoiced_id,
        object_type: invoice.invoiced_type,
        main: true
      )
      invoice.invoice_items.where(subscription_id: nil)[1..-1].each do |ii|
        ii.update_attributes(
          object_id: invoice.invoiced_id,
          object_type: invoice.invoiced_type
        )
      end
      subscription_item = invoice.invoice_items.where.not(subscription_id: nil).first
      next unless subscription_item

      subscription_item.update_attributes(
        object_id: subscription_item.subscription_id,
        object_type: 'Subscription'
      )
    end
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
      ii.invoice.update_attributes(
        invoiced_id: ii.object_id,
        invoiced_type: ii.object_type
      )
    end
    InvoiceItem.where(object_type: 'Subscription').each do |ii|
      ii.update_attributes(
        subscription_id: ii.object_id
      )
    end
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
