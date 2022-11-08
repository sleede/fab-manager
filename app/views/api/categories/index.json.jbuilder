# frozen_string_literal: true

json.array!(@categories) do |category|
  json.extract! category, :id, :name
  json.related_to category.events.count if current_user&.admin?
end
