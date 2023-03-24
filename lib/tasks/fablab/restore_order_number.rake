# frozen_string_literal: true

namespace :fablab do
  desc 'Scans PDF files of invoices to find order numbers'
  task restore_order_number: :environment do |_task, _args|
    order_text = [
      I18n.t('invoices.order_number', **{ NUMBER: 'REPLACE' }).gsub('REPLACE', ''),
      I18n.t('invoices.order_number', locale: 'en', **{ NUMBER: 'REPLACE' }).gsub('REPLACE', ''),
      I18n.t('invoices.order_number', locale: 'fr', **{ NUMBER: 'REPLACE' }).gsub('REPLACE', '')
    ]
    Invoice.order(id: :asc).find_each do |invoice|
      next unless File.exist?(invoice.file)

      found = false
      reader = PDF::Reader.new(invoice.file)
      page = reader.pages.first
      page.text.scan(/^.+/).each do |line|
        next unless order_text.any? { |label| line.include? label }
        break if found

        order_text.each do |label|
          next unless line.include? label

          number = line.gsub(label, '').strip
          invoice.update(order_number: number)
          found = true
        end
      end
    end
    Order.where(reference: nil).order(id: :asc).find_each do |order|
      order.update(reference: PaymentDocumentService.generate_order_number(order))
    end
    Invoice.where(order_number: nil).order(id: :asc).find_each do |invoice|
      next unless invoice.payment_schedule_item.nil?

      unless invoice.order.nil?
        invoice.update(order_number: invoice.order.reference)
        next
      end

      invoice.update(order_number: PaymentDocumentService.generate_order_number(invoice))
    end
    PaymentSchedule.order(id: :asc).find_each do |schedule|
      schedule.update(order_number: PaymentDocumentService.generate_order_number(schedule))
      schedule.ordered_items.each do |item|
        item.invoice&.update(order_number: schedule.order_number)
      end
    end
  end
end
