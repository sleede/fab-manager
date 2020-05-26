# frozen_string_literal: true

namespace :fablab do
  namespace :setup do
    desc 'assign all footprints to existing Invoice records'
    task chain_invoices_records: :environment do
      if Invoice.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = STDIN.gets.chomp
        next unless confirm == 'y'
      end

      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        Invoice.where('created_at > ?', last_period.end_at).order(:id).each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        Invoice.order(:id).all.each(&:chain_record)
      end
    end

    desc 'assign all footprints to existing InvoiceItem records'
    task chain_invoices_items_records: :environment do
      if InvoiceItem.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = STDIN.gets.chomp
        next unless confirm == 'y'
      end

      if AccountingPeriod.count.positive?
        last_period = AccountingPeriod.order(start_at: :desc).first
        puts "Regenerating from #{last_period.end_at}..."
        InvoiceItem.where('created_at > ?', last_period.end_at).order(:id).each(&:chain_record)
      else
        puts '(Re)generating all footprint...'
        InvoiceItem.order(:id).all.each(&:chain_record)
      end
    end

    desc 'assign all footprints to existing HistoryValue records'
    task chain_history_values_records: :environment do
      if HistoryValue.where.not(footprint: nil).count.positive?
        print 'WARNING: Footprints were already generated. Regenerate? (y/n) '
        confirm = STDIN.gets.chomp
        next unless confirm == 'y'
      end

      HistoryValue.order(:id).all.each(&:chain_record)
    end

    desc 'assign environment value to all invoices'
    task set_environment_to_invoices: :environment do
      Invoice.all.each do |i|
        i.environment = Rails.env
        i.save!
      end
    end

    desc 'add missing VAT rate to history'
    task :add_vat_rate, %i[rate date] => :environment do |_task, args|
      raise 'Missing argument. Usage exemple: rails fablab:setup:add_vat_rate[20,2014-01-01]. Use 0 to disable' unless args.rate && args.date

      if args.rate == '0'
        setting = Setting.find_by(name: 'invoice_VAT-active')
        HistoryValue.create!(
          setting_id: setting.id,
          user_id: User.admins.first.id,
          value: 'false',
          created_at: DateTime.parse(args.date)
        )
      else
        setting = Setting.find_by(name: 'invoice_VAT-rate')
        HistoryValue.create!(
          setting_id: setting.id,
          user_id: User.admins.first.id,
          value: args.rate,
          created_at: DateTime.parse(args.date)
        )
      end
    end

    desc 'migrate PDF invoices to folders numbered by invoicing_profile'
    task migrate_pdf_invoices_folders: :environment do
      puts 'No invoices, exiting...' and return if Invoice.count.zero?

      require 'fileutils'
      Invoice.all.each do |i|
        invoicing_profile = i.invoicing_profile
        user_id = invoicing_profile.user_id

        src = "invoices/#{user_id}/#{i.filename}"
        dest = "tmp/invoices/#{invoicing_profile.id}"

        if FileTest.exist?(src)
          FileUtils.mkdir_p dest
          FileUtils.mv src, "#{dest}/#{i.filename}", force: true
        end
      end
      FileUtils.rm_rf 'invoices'
      FileUtils.mv 'tmp/invoices', 'invoices'
    end

    desc 'migrate environment variables to the database (settings)'
    task env_to_db: :environment do
      include ApplicationHelper

      mapping = [
        %w[_ PHONE_REQUIRED phone_required true],
        %w[_ GA_ID tracking_id],
        %w[_ BOOK_SLOT_AT_SAME_TIME book_overlapping_slots true],
        %w[_ SLOT_DURATION slot_duration 60],
        %w[_ EVENTS_IN_CALENDAR events_in_calendar false],
        %w[! FABLAB_WITHOUT_SPACES spaces_module]
      ]

      mapping.each do |m|
        setting = Setting.find_or_initialize_by(name: m[2])
        value = ENV.fetch(m[1], m[3])
        next unless value

        value = (!str_to_bool(value)).to_s if m[0] == '!'
        setting.value = value
        setting.save
      end
    end
  end
end
