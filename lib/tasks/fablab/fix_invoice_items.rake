# frozen_string_literal: true

require 'integrity/archive_helper'

# This take will ensure data integrity for invoices_items.
# Due a an unknown bug, some invoice items may not contains the reference to their object.
# This task will re-associate these items with their reservation/subscription/etc
namespace :fablab do
  desc 'Associate the invoice_items w/o object'
  task fix_invoice_items: :environment do |_task, _args|
    next unless InvoiceItem.where(object_type: nil)
                           .or(InvoiceItem.where(object_id: nil))
                           .count
                           .positive?

    include ActionView::Helpers::NumberHelper

    # check the footprints and save the archives
    Integrity::ArchiveHelper.check_footprints
    ActiveRecord::Base.transaction do
      periods = Integrity::ArchiveHelper.backup_and_remove_periods

      # fix invoice items data
      InvoiceItem.where(object_type: nil)
                 .or(InvoiceItem.where(object_id: nil))
                 .find_each do |ii|
        invoice = ii.invoice
        next if ii.object_type == 'Error'

        other_items = invoice.invoice_items.where.not(id: ii.id)
        puts "\e[4;33mFound an invalid InvoiceItem\e[0m"
        puts '=============================================='
        puts "Invoice #{invoice.id} (# #{invoice.reference})"
        puts "Total: #{number_to_currency(invoice.total / 100.0)}"
        puts "Customer: #{invoice.invoicing_profile.full_name} (#{invoice.invoicing_profile.email})"
        puts "Operator: #{invoice.operator_profile&.user&.profile&.full_name} (#{invoice.operator_profile&.user&.email})"
        puts "Date: #{invoice.created_at}"
        puts '=============================================='
        puts "Concerned item: #{ii.id}"
        puts "Item subject: #{ii.description}."
        other_items.find_each do |oii|
          puts '=============================================='
          puts "Other item: #{oii.description} (#{oii.id})"
          puts "Other item object: #{oii.object_type} #{oii.object_id}"
          puts "Other item slots: #{oii.object.try(:slots)&.map { |s| "#{s.start_at} - #{s.end_at}" }}"
          print "\e[1;34m[ ? ]\e[0m Associate the item with #{oii.object_type} #{oii.object_id} ? (y/N) > "
          confirm = $stdin.gets.chomp
          if confirm == 'y'
            ii.update(object_id: oii.object_id, object_type: oii.object_type)
            break
          end
        end
        ii.reload
        if ii.object_id.nil? || ii.object_type.nil?
          puts "\n\e[0;31mERROR\e[0m: InvoiceItem(#{ii.id}) was not associated with an object. Please open a rails console " \
               "to manually fix the issue using `InvoiceItem.find(#{ii.id}.update(object_id: XXX, object_type: 'XXX')`.\n"
        end
      end

      # chain records
      puts 'Chaining all record. This may take a while...'
      InvoiceItem.order(:id).all.each(&:chain_record)
      Invoice.order(:id).all.each(&:chain_record)

      # re-create all archives from the memory dump
      Integrity::ArchiveHelper.restore_periods(periods)
    end
  end
end
