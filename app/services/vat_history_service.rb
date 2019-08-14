# frozen_string_literal: true

# Provides the VAT rate in use at the given date
class VatHistoryService
  # return the VAT rate for the given Invoice/Avoir
  def invoice_vat(invoice)
    if invoice.is_a?(Avoir)
      vat_rate(invoice.avoir_date)
    else
      vat_rate(invoice.created_at)
    end
  end

  # return the VAT rate foe the given date
  def vat_rate(date)
    @vat_rates = vat_history if @vat_rates.nil?

    first_rate = @vat_rates.first
    return first_rate[:rate] if date < first_rate[:date]

    @vat_rates.each_index do |i|
      return @vat_rates[i][:rate] if date >= @vat_rates[i][:date] && (@vat_rates[i + 1].nil? || date < @vat_rates[i + 1][:date])
    end
  end

  private

  def vat_history
    key_dates = []
    Setting.find_by(name: 'invoice_VAT-rate').history_values.each do |rate|
      key_dates.push(date: rate.created_at, rate: rate.value.to_i)
    end
    Setting.find_by(name: 'invoice_VAT-active').history_values.each do |v|
      key_dates.push(date: v.created_at, rate: 0) if v.value == 'false'
    end
    key_dates.sort_by { |k| k[:date] }
  end
end