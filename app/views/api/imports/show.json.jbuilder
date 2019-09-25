# frozen_string_literal: true

json.extract! @import, :id, :category, :user_id, :update_field, :created_at, :updated_at, :results
json.user do
  json.full_name @import.user&.profile&.full_name
end
