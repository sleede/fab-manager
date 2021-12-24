# frozen_string_literal: true

# Provides the VAT rate in use at the given date
class VatHistoryService
  # return the VAT rate for the given InvoiceItem
  def invoice_vat(invoice_item)
    if invoice_item.invoice.is_a?(Avoir)
      vat_rate(invoice_item.invoice.avoir_date, invoice_item.invoice_item_type)
    else
      vat_rate(invoice_item.invoice.created_at, invoice_item.invoice_item_type)
    end
  end

  # return the VAT rate for the given date and vat type
  def vat_rate(date, vat_rate_type)
    vat_rates = vat_history(vat_rate_type)

    first_rate = vat_rates.first
    return first_rate[:rate] if date < first_rate[:date]

    vat_rates.each_index do |i|
      return vat_rates[i][:rate] if date >= vat_rates[i][:date] && (vat_rates[i + 1].nil? || date < vat_rates[i + 1][:date])
    end
  end

  private

  def vat_history(vat_rate_type)
    chronology = []
    end_date = DateTime.current
    Setting.find_by(name: 'invoice_VAT-active').history_values.order(created_at: 'DESC').each do |v|
      chronology.push(start: v.created_at, end: end_date, enabled: v.value == 'true')
      end_date = v.created_at
    end
    chronology.push(start: DateTime.new(0), end: end_date, enabled: false)
    date_rates = []
    vat_rate_history_values = []
    if vat_rate_type.present?
      vat_rate_by_type = Setting.find_by(name: "invoice_VAT-rate_#{vat_rate_type}")&.history_values&.order(created_at: 'ASC')
      first_vat_rate_by_type = vat_rate_by_type&.select { |v| v.value.present? }&.first
      if first_vat_rate_by_type
        vat_rate_history_values = Setting.find_by(name: 'invoice_VAT-rate').history_values.where('created_at < ?', first_vat_rate_by_type.created_at).order(created_at: 'ASC').to_a
        vat_rate_by_type = Setting.find_by(name: "invoice_VAT-rate_#{vat_rate_type}").history_values.where('created_at >= ?', first_vat_rate_by_type.created_at).order(created_at: 'ASC')
        vat_rate_by_type.each do |rate|
          if rate.value.blank?
            vat_rate = Setting.find_by(name: 'invoice_VAT-rate').history_values.where('created_at < ?', rate.created_at).order(created_at: 'DESC').first
            rate.value = vat_rate.value
          end
          vat_rate_history_values.push(rate)
        end
      else
        vat_rate_history_values = Setting.find_by(name: 'invoice_VAT-rate').history_values.order(created_at: 'ASC').to_a
      end
      vat_rate_history_values.each do |rate|
        range = chronology.select { |p| rate.created_at.to_i.between?(p[:start].to_i, p[:end].to_i) }.first
        date = range[:enabled] ? rate.created_at : range[:end]
        date_rates.push(date: date, rate: rate.value.to_i)
      end
      chronology.reverse_each do |period|
        date_rates.push(date: period[:start], rate: 0) unless period[:enabled]
      end
    else
      date_rates.push(date: chronology[-1][:start], rate: 0)
    end
    date_rates.sort_by { |k| k[:date] }
  end
end
