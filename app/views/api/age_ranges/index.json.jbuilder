# frozen_string_literal: true

json.array!(@age_ranges) do |ar|
  json.extract! ar, :id, :name
  json.related_to ar.events.count if current_user&.admin?
end
