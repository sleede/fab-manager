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

  # return the VAT rate for the given date
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
    chronology = []
    end_date = DateTime.current
    Setting.find_by(name: 'invoice_VAT-active').history_values.order(created_at: 'DESC').each do |v|
      chronology.push(start: v.created_at, end: end_date, enabled: v.value == 'true')
      end_date = v.created_at
    end
    chronology.push(start: DateTime.new(0), end: end_date, enabled: false)
    date_rates = []
    Setting.find_by(name: 'invoice_VAT-rate').history_values.order(created_at: 'ASC').each do |rate|
      range = chronology.select { |p| rate.created_at.to_i.between?(p[:start].to_i, p[:end].to_i) }.first
      date = range[:enabled] ? rate.created_at : range[:end]
      date_rates.push(date: date, rate: rate.value.to_i)
    end
    chronology.reverse_each do |period|
      date_rates.push(date: period[:start], rate: 0) unless period[:enabled]
    end
    date_rates.sort_by { |k| k[:date] }
  end
end
