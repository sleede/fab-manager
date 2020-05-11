# frozen_string_literal: true

# regenerate the accounting periods affected by the current bug (period totals are wrong due to wrong VAT computation)
class FixAccountingPeriods < ActiveRecord::Migration[5.2]
  def change
    # first, check the footprints
    check_footprints

    # if everything is ok, proceed with migration
    # remove periods (backup their parameters in memory)
    periods = backup_and_remove_periods
    # recreate periods from memory dump
    restore_periods(periods)
  end

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
    return [] unless AccountingPeriod.where("created_at > '2019-08-01'").count.positive?

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

end
