# frozen_string_literal: true

json.array!(@accounting_periods) do |ap|
  json.extract! ap, :id, :start_at, :end_at, :closed_at, :closed_by, :footprint, :created_at
  json.period_total ap.period_total / 100.0
  json.perpetual_total ap.perpetual_total / 100.0
  json.chained_footprint ap.check_footprint
  json.user_name "#{ap.first_name} #{ap.last_name}"
end
