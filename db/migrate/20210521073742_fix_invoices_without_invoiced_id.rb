# frozen_string_literal: true

require 'integrity/archive_helper'

# This migration will ensure data integrity for invoices.
# A bug introduced with v4.7.0 has made invoices without invoiced_id for Reservations.
# This issue is concerning slots restricted to subscribers, when the restriction was manually overridden by an admin.
class FixInvoicesWithoutInvoicedId < ActiveRecord::Migration[5.2]
  def up
    return unless Invoice.where(invoiced_id: nil).count.positive?

    # check the footprints and save the archives
    Integrity::ArchiveHelper.check_footprints
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    # fix invoices data
    Invoice.where(invoiced_id: nil).each do |invoice|
      if invoice.invoiced_type != 'Reservation'
        STDERR.puts "WARNING: Invoice #{invoice.id} is not about a reservation, ignoring..."
        next
      end

      ii = invoice.invoice_items.where(subscription_id: nil).first
      reservable = find_reservable(ii)
      if reservable
        if reservable.is_a? Event
          STDERR.puts "WARNING: invoice #{invoice.id} may be linked to the Event #{reservable.id}. This is unsupported, ignoring..."
          next
        end
        ::Reservation.create!(
          reservable_id: reservable.id,
          reservable_type: reservable.class.name,
          slots_attributes: slots_attributes(invoice, reservable),
          statistic_profile_id: StatisticProfile.find_by(user: invoice.user).id
        )
        invoice.update_attributes(invoiced: reservation)
      else
        STDERR.puts "WARNING: Unable to guess the reservable for invoice #{invoice.id}, ignoring..."
      end
    end

    # chain records
    puts 'Chaining all record. This may take a while...'
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end

  def down; end

  private

  def find_reservable(invoice_item)
    descr = /^([a-zA-Z\u00C0-\u017F]+\s+)+/.match(invoice_item.description)[0].strip[/(.*)\s/, 1]
    reservable = InvoiceItem.where('description LIKE ?', "#{descr}%")
                            .map(&:invoice)
                            .filter { |i| !i.invoiced_id.nil? }
                            .map(&:invoiced)
                            .map(&:reservable)
                            .first
    reservable ||= [Machine, Training, Space].map { |c| c.where('name LIKE ?', "#{descr}%") }
                                             .filter { |r| r.count.positive? }
                                             .first
                                             &.first

    reservable || Event.where('title LIKE ?', "#{descr}%").first
  end

  def find_slots(invoice)
    invoice.invoice_items.map do |ii|
      start = DateTime.parse(ii.description)
      end_time = DateTime.parse(/- (.+)$/.match(ii.description)[1])
      [start, DateTime.new(start.year, start.month, start.day, end_time.hour, end_time.min, end_time.sec, end_time.zone)]
    end
  end

  def find_availability(reservable, slot)
    return if reservable.is_a? Event

    availability = reservable.availabilities.where('start_at <= ? AND end_at >= ?', slot[0], slot[1]).first
    unless availability
      STDERR.puts "WARNING: Unable to find an availability for #{reservable.class.name} #{reservable.id}, at #{slot[0]}..."
    end
    availability
  end

  def slots_attributes(invoice, reservable)
    find_slots(invoice).map do |slot|
      {
        start_at: slot[0],
        end_at: slot[1],
        availability_id: find_availability(reservable, slot).id,
        offered: invoice.total.zero?
      }
    end
  end
end
