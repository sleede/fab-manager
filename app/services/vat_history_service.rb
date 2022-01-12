# frozen_string_literal: true

# Provides the VAT rate in use at the given date
class VatHistoryService
  # @return the VAT rate for the given Invoice
  def invoice_vat(invoice)
    vat_rate_group = {}
    invoice.invoice_items.each do |item|
      vat_type = item.invoice_item_type
      vat_rate_group[vat_type] = { vat_rate: invoice_item_vat(item), total_vat: 0, amount: 0 } unless vat_rate_group[vat_type]
      vat_rate_group[vat_type][:total_vat] += item.vat
      vat_rate_group[vat_type][:amount] += item.amount.to_i
    end
    vat_rate_group
  end

  # return the VAT rate for the given InvoiceItem
  def invoice_item_vat(invoice_item)
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
    # now chronology contains something like one of the following:
    # - [{start: 0000-01-01, end: now, enabled: false}] => VAT was never enabled
    # - [
    #     {start: fab-manager initial setup date, end: now, enabled: true},
    #     {start: 0000-01-01, end: fab-manager initial setup date, enabled: false}
    #   ] => VAT was enabled from the beginning
    # - [
    #    {start: [date disabled], end: now, enabled: false},
    #    {start: [date enable], end: [date disabled], enabled: true},
    #    {start: fab-manager initial setup date, end: [date enabled], enabled: false},
    #    {start: 0000-01-01, end: fab-manager initial setup date, enabled: false}
    #  ] => VAT was enabled at some point, and disabled at some other point later

    date_rates = []
    if vat_rate_type.present?
      vat_rate_by_type = Setting.find_by(name: "invoice_VAT-rate_#{vat_rate_type}")&.history_values&.order(created_at: 'ASC')
      first_vat_rate_by_type = vat_rate_by_type&.select { |v| v.value.present? }&.first
      if first_vat_rate_by_type
        # before the first VAT rate was defined for the given type, the general VAT rate is used
        vat_rate_history_values = Setting.find_by(name: 'invoice_VAT-rate')
                                         .history_values.where('created_at < ?', first_vat_rate_by_type.created_at)
                                         .order(created_at: 'ASC').to_a
        # after that, the VAT rate for the given type is used
        vat_rate_by_type = Setting.find_by(name: "invoice_VAT-rate_#{vat_rate_type}")
                                  .history_values.where('created_at >= ?', first_vat_rate_by_type.created_at)
                                  .order(created_at: 'ASC')
        vat_rate_by_type.each do |rate|
          if rate.value.blank?
            # if, at some point in the history, a blank rate was set, the general VAT rate is used instead
            vat_rate = Setting.find_by(name: 'invoice_VAT-rate')
                              .history_values.where('created_at < ?', rate.created_at)
                              .order(created_at: 'DESC')
                              .first
            rate.value = vat_rate.value
          end
          vat_rate_history_values.push(rate)
        end
      else
        # if no VAT rate is defined for the given type, the general VAT rate is always used
        vat_rate_history_values = Setting.find_by(name: 'invoice_VAT-rate').history_values.order(created_at: 'ASC').to_a
      end

      # Now we have all the rates history, we can build the final chronology, depending on whether VAT was enabled or not
      vat_rate_history_values.reverse_each do |rate|
        # when the VAT rate was enabled, set the date it was enabled and the rate
        range = chronology.find { |p| rate.created_at.to_i.between?(p[:start].to_i, p[:end].to_i) }
        date = range[:enabled] ? rate.created_at : range[:end]
        date_rates.push(date: date, rate: rate.value.to_i) unless date_rates.find { |d| d[:date] == date }
      end
      chronology.reverse_each do |period|
        # when the VAT rate was disabled, set the date it was disabled and rate=0
        date_rates.push(date: period[:start], rate: 0) unless period[:enabled]
      end
    else
      # if no VAT rate type is given, we return rate=0 from 0000-01-01
      date_rates.push(date: chronology[-1][:start], rate: 0)
    end

    # finally, we return the chronology, sorted by dates (ascending)
    date_rates.sort_by { |k| k[:date] }
  end
end
