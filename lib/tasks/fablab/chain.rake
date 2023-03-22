# frozen_string_literal: true

namespace :fablab do
  namespace :chain do
    desc 'assign all footprints to existing records'
    task :all, [:force] => :environment do |_task, args|
      if Invoice.where.not(footprint: nil).count.positive? && args.force != 'force'
        print 'All footprints will be regenerated. Are you sure? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_invoices
      chain_invoice_items
      chain_history_values
      chain_payment_schedules
      chain_payment_schedules_items
      chain_payment_schedules_objects if ActiveRecord::Base.connection.table_exists? PaymentScheduleObject.arel_table
    end

    desc 'assign all footprints to existing Invoice records'
    task invoices: :environment do
      if Invoice.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_invoices
    end

    def chain_invoices
      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        Invoice.where('created_at > ?', last_period.end_at).order(:id).find_each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        Invoice.order(:id).find_each(&:chain_record)
      end
    end

    desc 'assign all footprints to existing InvoiceItem records'
    task invoices_items: :environment do
      if InvoiceItem.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_invoice_items
    end

    def chain_invoice_items
      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        InvoiceItem.where('created_at > ?', last_period.end_at).order(:id).find_each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        InvoiceItem.order(:id).find_each(&:chain_record)
      end
    end

    desc 'assign all footprints to existing HistoryValue records'
    task history_values: :environment do
      if HistoryValue.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_history_values
    end

    def chain_history_values
      HistoryValue.order(:created_at).find_each(&:chain_record)
    end

    desc 'assign all footprints to existing PaymentSchedule records'
    task payment_schedule: :environment do
      if PaymentSchedule.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_payment_schedules
    end

    def chain_payment_schedules
      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        PaymentSchedule.where('created_at > ?', last_period.end_at).order(:id).find_each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        PaymentSchedule.order(:id).find_each(&:chain_record)
      end
    end

    desc 'assign all footprints to existing PaymentScheduleItem records'
    task payment_schedule_item: :environment do
      if PaymentScheduleItem.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_payment_schedules_items
    end

    def chain_payment_schedules_items
      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        PaymentScheduleItem.where('created_at > ?', last_period.end_at).order(:id).find_each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        PaymentScheduleItem.order(:id).find_each(&:chain_record)
      end
    end

    desc 'assign all footprints to existing PaymentScheduleObject records'
    task payment_schedule_object: :environment do
      if PaymentScheduleObject.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = $stdin.gets.chomp
        next unless confirm == 'y'
      end
      chain_payment_schedules_objects
    end

    def chain_payment_schedules_objects
      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        PaymentScheduleObject.where('created_at > ?', last_period.end_at).order(:id).find_each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        PaymentScheduleObject.order(:id).find_each(&:chain_record)
      end
    end
  end
end
