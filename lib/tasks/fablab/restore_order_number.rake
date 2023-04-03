# frozen_string_literal: true

namespace :fablab do
  desc 'Scans PDF files of invoices to find order numbers'
  task restore_order_number: :environment do |_task, _args|
    order_text = [
      I18n.t('invoices.order_number', **{ NUMBER: 'REPLACE' }).gsub('REPLACE', ''),
      I18n.t('invoices.order_number', locale: 'en', **{ NUMBER: 'REPLACE' }).gsub('REPLACE', ''),
      I18n.t('invoices.order_number', locale: 'fr', **{ NUMBER: 'REPLACE' }).gsub('REPLACE', '')
    ]
    max_id = ActiveRecord::Base.connection.execute('SELECT max(id) as max_id FROM invoices').first['max_id']
    Invoice.order(id: :asc).find_each do |invoice|
      print "Processing: #{invoice.id} / #{max_id}\r"
      next unless File.exist?(invoice.file)

      found = false
      reader = PDF::Reader.new(invoice.file)
      page = reader.pages.first
      page.text.scan(/^.+/).each do |line|
        next unless order_text.any? { |label| line.include? label }
        break if found

        order_text.each do |label|
          next unless line.include? label

          number = line.gsub(label, '').gsub(/\s{5,}.+$/, '').strip
          invoice.update(order_number: number)
          found = true
        end
      end
    end
    print "\nRestoring the store orders numbers...\n"
    Order.where(reference: nil).order(id: :asc).find_each do |order|
      order.update(reference: PaymentDocumentService.generate_order_number(order))
    end
    puts 'Filling the gaps for invoices numbers...'
    max = Invoice.where(order_number: nil).count
    Invoice.where(order_number: nil).order(id: :asc).find_each.with_index do |invoice, index|
      print "Processing: #{index} / #{max}\r"
      next unless invoice.payment_schedule_item.nil?

      unless invoice.order.nil?
        invoice.update(order_number: invoice.order.reference)
        next
      end

      invoice.update(order_number: PaymentDocumentService.generate_order_number(invoice))
    end
    puts 'Restoring the payment schedules numbers...'
    PaymentSchedule.order(id: :asc).find_each do |schedule|
      schedule.update(order_number: PaymentDocumentService.generate_order_number(schedule))
      schedule.ordered_items.each do |item|
        item.invoice&.update(order_number: schedule.order_number)
      end
    end
    puts 'Restoring the refund invoices numbers...'
    Avoir.where(order_number: nil).order(id: :asc).find_each do |refund|
      next if refund.invoice.nil?

      # refunds are validated against their avoir_date for inclusion in closed periods, so we must bypass the validation
      # (Invoices are validated on Time.current, so this was not necesseary above)
      refund.update_attribute('order_number', refund.invoice.order_number) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
