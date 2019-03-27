# frozen_string_literal: true

namespace :fablab do
  namespace :setup do
    desc 'assign all footprints to existing Invoice records'
    task chain_invoices_records: :environment do
      raise "Footprints were already generated, won't regenerate" if Invoice.where.not(footprint: nil).count.positive?

      Invoice.order(:created_at).all.each(&:chain_record)
    end

    desc 'assign all footprints to existing InvoiceItem records'
    task chain_invoices_items_records: :environment do
      raise "Footprints were already generated, won't regenerate" if InvoiceItem.where.not(footprint: nil).count.positive?

      InvoiceItem.order(:created_at).all.each(&:chain_record)
    end

    desc 'assign all footprints to existing HistoryValue records'
    task chain_history_values_records: :environment do
      raise "Footprints were already generated, won't regenerate" if HistoryValue.where.not(footprint: nil).count.positive?

      HistoryValue.order(:created_at).all.each(&:chain_record)
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
      raise 'Missing argument. Usage exemple: rake fablab:setup:add_vat_rate[20,2014-01-01]. Use 0 to disable' unless args.rate && args.date

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
  end
end
