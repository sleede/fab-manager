json.invoices do
  json.array!(invoices) do |invoice|
    json.extract! invoice, :id, :stp_invoice_id, :created_at, :reference, :footprint
    json.total number_to_currency(invoice.total / 100.0)
    json.invoiced do
      json.type invoice.invoiced_type
      json.id invoice.invoiced_id
      if invoice.invoiced_type == Subscription.name
        json.extract! invoice.invoiced, :stp_subscription_id, :created_at, :expiration_date, :canceled_at
        json.plan do
          json.extract! invoice.invoiced.plan, :id, :base_name, :interval, :interval_count, :stp_plan_id, :is_rolling
          json.group do
            json.extract! invoice.invoiced.plan.group, :id, :name
          end
        end
      elsif invoice.invoiced_type == Reservation.name
        json.extract! invoice.invoiced, :created_at, :stp_invoice_id
        json.reservable do
          json.type invoice.invoiced.reservable_type
          json.id invoice.invoiced.reservable_id
          if [Training.name, Machine.name, Space.name].include?(invoice.invoiced.reservable_type) &&
             !invoice.invoiced.reservable.nil?
            json.extract! invoice.invoiced.reservable, :name, :created_at
          elsif invoice.invoiced.reservable_type == Event.name && !invoice.invoiced.reservable.nil?
            json.extract! invoice.invoiced.reservable, :title, :created_at
            json.prices do
              json.standard_price number_to_currency(invoice.invoiced.reservable.amount / 100.0)
              json.other_prices invoice.invoiced.reservable.event_price_categories do |price|
                json.amount number_to_currency(price.amount / 100.0)
                json.price_category do
                  json.extract! price.price_category, :id, :name, :created_at
                end
              end
            end
          end
        end
      end
    end
    json.user do
      json.extract! invoice.user, :id, :email, :created_at
      json.profile do
        json.extract! invoice.user.profile, :id, :first_name, :last_name, :birthday, :phone
        json.gender invoice.user.profile.gender ? 'male' : 'female'
      end
    end
    json.invoice_items invoice.invoice_items do |item|
      json.extract! item, :id, :stp_invoice_item_id, :created_at, :description, :footprint
      json.amount number_to_currency(item.amount / 100.0)
    end
  end
end

json.totals do
  json.period_total period_total / 100.0
  json.perpetual_total perpetual_total / 100.0
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
