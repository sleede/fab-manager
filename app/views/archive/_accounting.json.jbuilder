# frozen_string_literal: true

json.invoices do
  json.array!(invoices) do |invoice|
    json.extract! invoice[:invoice], :id, :stp_invoice_id, :created_at, :reference, :footprint
    json.total number_to_currency(invoice[:invoice].total / 100.0)
    json.invoiced do
      json.type invoice[:invoice].invoiced_type
      json.id invoice[:invoice].invoiced_id
      if invoice[:invoice].invoiced_type == Subscription.name
        json.partial! 'archive/subscription', invoiced: invoice[:invoice].invoiced
      elsif invoice[:invoice].invoiced_type == Reservation.name
        json.partial! 'archive/reservation', invoiced: invoice[:invoice].invoiced, vat_rate: invoice[:vat_rate]
      end
    end
    json.user do
      json.extract! invoice[:invoice].user, :id, :email, :created_at
      json.profile do
        json.extract! invoice[:invoice].user.profile, :id, :first_name, :last_name, :birthday, :phone
        json.gender invoice[:invoice].user.profile.gender ? 'male' : 'female'
      end
    end
    json.invoice_items invoice[:invoice].invoice_items do |item|
      json.extract! item, :id, :stp_invoice_item_id, :created_at, :description, :footprint
      json.partial! 'archive/vat', price: item.amount, vat_rate: invoice[:vat_rate]
    end
  end
end

json.totals do
  json.period_total number_to_currency(period_total / 100.0)
  json.perpetual_total number_to_currency(perpetual_total / 100.0)
end

json.software do
  json.name 'Fab-Manager'
  json.version software_version
  json.code_checksum code_checksum
end

json.previous_archive do
  json.filename previous_file
  json.checksum last_archive_checksum
end

json.period_footprint period_footprint
json.archive_date date
