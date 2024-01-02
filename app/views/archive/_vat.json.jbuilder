# frozen_string_literal: true

json.amount do
  json.without_tax number_to_currency((price - (price * vat_rate)) / 100.0, locale: CURRENCY_LOCALE)
  json.all_taxes_included number_to_currency(price / 100.0, locale: CURRENCY_LOCALE)
  json.vat_rate vat_rate.positive? ? number_to_percentage(vat_rate * 100) : 'none'
end
