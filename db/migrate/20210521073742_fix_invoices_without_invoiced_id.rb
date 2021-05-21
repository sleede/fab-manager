# frozen_string_literal: true

# This migration will ensure data integrity for invoices.
# A bug introduced with v4.7.0 has made invoices without invoiced_id for Reservations.
# This issue is concerning slots restricted to subscribers, when the restriction was manually overridden by an admin.
class FixInvoicesWithoutInvoicedId < ActiveRecord::Migration[5.2]
  def up
    return unless Invoice.where(invoiced_id: nil).count.positive?

    # check the footprints and save the archives
    check_footprints
    periods = backup_and_remove_periods

    # fix invoices data
    Invoice.where(invoiced_id: nil).each do |invoice|
      if invoice.total.zero?
        puts "Invoice #{invoice.id} has total = 0, destroying..."
        invoice.destroy
        next
      end
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
        reservation = ::Reservation.create!(
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
    restore_periods(periods)
  end

  def down; end

  private

  def check_footprints
    if AccountingPeriod.count.positive?
      last_period = AccountingPeriod.order(start_at: :desc).first
      puts "Checking invoices footprints from #{last_period.end_at}. This may take a while..."
      Invoice.where('created_at > ?', last_period.end_at).order(:id).each do |i|
        raise "Invalid footprint for invoice #{i.id}" unless i.check_footprint
      end
    else
      puts 'Checking all invoices footprints. This may take a while...'
      Invoice.order(:id).all.each do |i|
        raise "Invalid footprint for invoice #{i.id}" unless i.check_footprint
      end
    end
  end

  # will return an array of hash containing the removed periods data
  def backup_and_remove_periods
    return [] unless AccountingPeriod.where("created_at > '2019-08-01' AND created_at < '2020-05-12'").count.positive?

    puts 'Removing erroneous accounting archives...'
    # 1. remove protection for AccountingPeriods
    execute("DROP RULE IF EXISTS accounting_periods_del_protect ON #{AccountingPeriod.arel_table.name};")
    # 2. backup AccountingPeriods in memory
    periods = []
    AccountingPeriod.where("created_at > '2019-08-01'").each do |p|
      periods.push(
        start_at: p.start_at,
        end_at: p.end_at,
        closed_at: p.closed_at,
        closed_by: p.closed_by
      )
    end
    # 3. Delete periods from database
    AccountingPeriod.where("created_at > '2019-08-01'").each do |ap|
      execute("DELETE FROM accounting_periods WHERE ID=#{ap.id};")
    end
    periods
  end

  def restore_periods(periods)
    return unless periods.size.positive?

    # 1. recreate AccountingPeriods
    puts 'Recreating accounting archives. This may take a while...'
    periods.each do |p|
      AccountingPeriod.create!(
        start_at: p[:start_at],
        end_at: p[:end_at],
        closed_at: p[:closed_at],
        closed_by: p[:closed_by]
      )
    end
    # 2. reset protection for AccountingPeriods
    execute("CREATE RULE accounting_periods_del_protect AS ON DELETE TO #{AccountingPeriod.arel_table.name} DO INSTEAD NOTHING;")
  end


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
      # FIXME, datetime parsing is KO
      start = DateTime.parse(ii.description)
      end_time = DateTime.parse(/- (.+)$/.match(ii.description)[1])
      [start, DateTime.new(start.year, start.month, start.day, end_time.hour, end_time.min, end_time.sec, end_time.zone)]
    end
  end

  def find_availability(reservable, slot)
    return if reservable.is_a? Event

    availability = reservable.availabilities.where('start_at <= ? AND end_at >= ?', slot[0], slot[1]).first
    unless availability
      STDERR.puts "WARNING: Unable to find an availability for #{reservable.class.name} #{reservable.id}, at #{slot[0]}, creating..."
      availability = reservable.availabilities.create!(start_at: slot[0], end_at: slot[1])
    end
    availability
  end

  def slots_attributes(invoice, reservable)
    find_slots(invoice).map do |slot|
      {
        start_at: slot[0],
        end_at: slot[1],
        availability_id: find_availability(reservable, slot)&.id,
        offered: invoice.total.zero?
      }
    end
  end
end
