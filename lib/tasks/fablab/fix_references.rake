# frozen_string_literal: true

namespace :fablab do
  desc 'Fill the holes in the logical sequence of invoices references'
  task fix_references: :environment do |_task, _args|
    include ActionView::Helpers::NumberHelper
    include DbHelper

    user = User.adminsys || User.admins.first

    ActiveRecord::Base.transaction do
      missing_references = {}

      # browse invoices to list missing reference
      puts 'Computing missing references...'
      not_closed(Invoice).find_each do |invoice|
        number = Invoices::NumberService.number(invoice)
        next if number == 1

        previous = Invoice.where('created_at < :date', date: db_time(invoice.created_at))
                          .order(created_at: :desc)
                          .limit(1)
                          .first
        previous_saved_number = Invoices::NumberService.number(previous)
        previous_number = number - 1
        loop do
          break if previous_number.zero? || previous_number == previous_saved_number

          previous_invoice = Invoices::NumberService.find_by_number(previous_number, date: invoice.created_at)
          break if previous_invoice.present?

          missing_references[invoice.created_at] ||= []
          missing_references[invoice.created_at].push(previous_number)

          previous_number -= 1
        end
      end

      # create placeholder invoices for found missing references
      puts 'Creating missing invoices...'
      total = missing_references.values.filter(&:present?).flatten.count
      counter = 1
      missing_references.each_pair do |date, numbers|
        numbers.each_with_index do |number, index|
          print "#{counter} / #{total}\r"
          invoice = Invoice.new(
            total: 0,
            invoicing_profile: user.invoicing_profile,
            statistic_profile: user.statistic_profile,
            operator_profile: user.invoicing_profile,
            payment_method: '',
            created_at: date - (index + 1).seconds,
            invoice_items_attributes: [{
              amount: 0,
              description: I18n.t('invoices.null_invoice'),
              object_type: 'Error',
              object_id: 1,
              main: true
            }]
          )
          invoice.reference = PaymentDocumentService.generate_numbered_reference(number, invoice)
          invoice.save!
          counter += 1
        end
      end
      print "\n"
    end
  end

  # @param klass [Class]
  # @return [ActiveRecord::Relation<klass>,Class]
  def not_closed(klass)
    if AccountingPeriod.count.positive?
      last_period = AccountingPeriod.order(start_at: :desc).first
      klass.where('created_at > ?', last_period.end_at)
    else
      klass
    end
  end
end
