# frozen_string_literal: true

json.array!(@accounting_periods) do |ap|
  json.extract! ap, :id, :start_at, :end_at, :closed_at, :closed_by, :created_at
  json.user_name "#{ap.first_name} #{ap.last_name}"
end
