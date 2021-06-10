# frozen_string_literal: true

json.invoices do
  json.array!(invoices) do |invoice|
    json.extract! invoice[:invoice], :id, :payment_method, :created_at, :reference, :footprint
    if invoice[:invoice].payment_gateway_object
      json.payment_gateway_object do
        json.id invoice[:invoice].payment_gateway_object.gateway_object_id
        json.type invoice[:invoice].payment_gateway_object.gateway_object_type
      end
    end
    json.total number_to_currency(invoice[:invoice].total / 100.0)
    json.user do
      json.extract! invoice[:invoice].invoicing_profile, :user_id, :email, :first_name, :last_name
      json.address invoice[:invoice].invoicing_profile&.address&.address
      json.invoicing_profile_id invoice[:invoice].invoicing_profile.id
      if invoice[:invoice].invoicing_profile.organization
        json.organization do
          json.extract! invoice[:invoice].invoicing_profile.organization, :name, :id
          json.address invoice[:invoice].invoicing_profile.organization&.address&.address
        end
      end
    end
    json.invoice_items invoice[:invoice].invoice_items do |item|
      json.extract! item, :id, :main, :created_at, :description, :footprint
      if item.payment_gateway_object
        json.payment_gateway_object do
          json.id item.payment_gateway_object.gateway_object_id
          json.type item.payment_gateway_object.gateway_object_type
        end
      end
      json.object do
        json.type item.object_type
        json.id item.object_id
        json.main item.main
      end
      json.partial! 'archive/vat', price: item.amount, vat_rate: invoice[:vat_rate]
    end
  end
end

json.payment_schedules do
  json.array!(schedules) do |schedule|
    json.extract! schedule, :id, :payment_method, :created_at, :reference, :footprint
    json.payment_gateway_objects schedule.payment_gateway_objects do |object|
      json.id object.gateway_object_id
      json.type object.gateway_object_type
    end
    json.total number_to_currency(schedule.total / 100.0)
    json.user do
      json.extract! schedule.invoicing_profile, :user_id, :email, :first_name, :last_name
      json.address schedule.invoicing_profile&.address&.address
      json.invoicing_profile_id schedule.invoicing_profile.id
      if schedule.invoicing_profile.organization
        json.organization do
          json.extract! schedule.invoicing_profile.organization, :name, :id
          json.address schedule.invoicing_profile.organization&.address&.address
        end
      end
    end
    json.deadlines schedule.payment_schedule_items do |item|
      json.extract! item, :id, :due_date, :state, :details, :invoice_id, :footprint, :created_at
      json.amount number_to_currency(item.amount / 100.0)
    end
    json.objects schedule.payment_schedule_objects do |object|
      json.type object.object_type
      json.id object.object_id
      json.main object.main
    end
  end
end

json.totals do
  json.period_total number_to_currency(period_total / 100.0)
  json.perpetual_total number_to_currency(perpetual_total / 100.0)
end

json.software do
  json.name 'Fab-manager'
  json.version software_version
  json.code_checksum code_checksum
end

json.previous_archive do
  json.filename previous_file
  json.checksum last_archive_checksum
end

json.period_footprint period_footprint
json.archive_date date
