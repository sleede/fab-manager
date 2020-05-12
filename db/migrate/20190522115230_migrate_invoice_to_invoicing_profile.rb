# frozen_string_literal: true

# migrate the invoices from being attached to a user to invoicing_profiles which are GDPR compliant
class MigrateInvoiceToInvoicingProfile < ActiveRecord::Migration[4.2]
  def up
    # first, check the footprints
    check_footprints

    # if everything is ok, proceed with migration
    # remove and save periods in memory
    periods = backup_and_remove_periods
    # migrate invoices
    puts 'Migrating invoices. This may take a while...'
    Invoice.order(:id).all.each do |i|
      user = User.find(i.user_id)
      operator = User.find_by(id: i.operator_id)
      i.update_column('invoicing_profile_id', user.invoicing_profile.id)
      i.update_column('statistic_profile_id', user.statistic_profile.id)
      i.update_column('operator_profile_id', operator&.invoicing_profile&.id)
      i.update_column('user_id', nil)
      i.update_column('operator_id', nil)
    end
    # chain all records
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)
    # write memory dump into database
    restore_periods(periods)
  end

  def down
    # here we don't check footprints to save processing time and because this is pointless when reverting the migrations

    # remove and save periods in memory
    periods = backup_and_remove_periods
    # reset invoices
    Invoice.order(:created_at).all.each do |i|
      i.update_column('user_id', i.invoicing_profile.user_id)
      i.update_column('operator_id', i.operator_profile.user_id)
      i.update_column('invoicing_profile_id', nil)
      i.update_column('statistic_profile_id', nil)
      i.update_column('operator_profile_id', nil)
    end
    # chain all records
    InvoiceItem.order(:id).all.each(&:chain_record)
    Invoice.order(:id).all.each(&:chain_record)
    # write memory dump into database
    restore_periods(periods)
  end

  def check_footprints
    if AccountingPeriod.count.positive?
      last_period = AccountingPeriod.order(start_at: 'DESC').first
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
    return [] unless AccountingPeriod.count.positive?

    puts 'Removing accounting archives...'
    # 1. remove protection for AccountingPeriods
    execute("DROP RULE IF EXISTS accounting_periods_del_protect ON #{AccountingPeriod.arel_table.name};")
    # 2. backup AccountingPeriods in memory
    periods = []
    AccountingPeriod.all.each do |p|
      periods.push(
        start_at: p.start_at,
        end_at: p.end_at,
        closed_at: p.closed_at,
        closed_by: p.closed_by
      )
    end
    # 3. Delete periods from database
    AccountingPeriod.all.each do |ap|
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
