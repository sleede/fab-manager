# frozen_string_literal: true

namespace :fablab do
  namespace :setup do
    desc 'assign all footprints to existing Invoice records'
    task chain_invoices_records: :environment do
      Invoice.order(:created_at).all.each do |i|
        i.chain_record
        i.save!
      end
    end

    desc 'assign all footprints to existing InvoiceItem records'
    task chain_invoices_items_records: :environment do
      InvoiceItem.order(:created_at).all.each do |i|
        i.chain_record
        i.save!
      end
    end
  end
end