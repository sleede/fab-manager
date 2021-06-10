# frozen_string_literal: true

json.array!(@durations) do |duration|
  json.name duration[:name]
  json.plans_ids duration[:plans]
end
