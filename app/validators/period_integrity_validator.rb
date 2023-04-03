# frozen_string_literal: true

# Validates that all invoices in the current accounting period are chained with footprints which ensure their integrity
class PeriodIntegrityValidator < ActiveModel::Validator
  def validate(record)
    invoices = record.invoices.includes(:invoice_items)

    invoices.each do |i|
      record.errors.add("invoice_#{i.reference}".to_sym, I18n.t('errors.messages.invalid_footprint')) unless i.check_footprint
    end
  end
end
