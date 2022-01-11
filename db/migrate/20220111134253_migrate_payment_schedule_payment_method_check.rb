# frozen_string_literal: true

require 'integrity/archive_helper'

# From this migration, blank payment methods for payment schedules will be removed and replaced by 'check'
class MigratePaymentSchedulePaymentMethodCheck < ActiveRecord::Migration[5.2]
  def up
    # first, check the footprints
    Integrity::ArchiveHelper.check_footprints

    # if everything is ok, proceed with migration
    # remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    # migrate the payment schedules
    PaymentSchedule.where(payment_method: '').order(:id).find_each do |ps|
      ps.update(payment_method: 'check')
    end

    # chain all records
    puts 'Chaining all record. This may take a while...'
    PaymentSchedule.order(:id).find_each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end

  def down
    # here we don't check footprints to save processing time and because this is pointless when reverting the migrations

    # remove and save periods in memory
    periods = Integrity::ArchiveHelper.backup_and_remove_periods

    # migrate the payment schedules
    PaymentSchedule.where(payment_method: 'check').order(:id).find_each do |ps|
      ps.update(payment_method: '')
    end

    # chain all records
    PaymentSchedule.order(:id).all.each(&:chain_record)

    # re-create all archives from the memory dump
    Integrity::ArchiveHelper.restore_periods(periods)
  end
end
