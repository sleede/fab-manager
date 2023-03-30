# frozen_string_literal: true

json.availabilities @availabilities do |availability|
  json.extract! availability, :id, :start_at, :end_at, :created_at
  json.available_type availability.available_type.classify
  json.available_ids availability.available_ids

  json.slots availability.slots do |slot|
    json.extract! slot, :id, :start_at, :end_at
  end
end
