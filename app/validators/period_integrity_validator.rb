# frozen_string_literal: true

# Validates that all invoices in the current accounting period are chained with footprints which ensure their integrity
class PeriodIntegrityValidator < ActiveModel::Validator
  def validate(record)
    the_end = record.end_at
    the_start = record.start_at

    invoices = Invoice.where('created_at >= :start_date AND created_at < :end_date', start_date: the_start, end_date: the_end)
                      .includes(:invoice_items)


    invoices.each do |i|
      record.errors["invoice_#{i.reference}".to_sym] << I18n.t('errors.messages.invalid_footprint') unless i.check_footprint
    end
  end
end
