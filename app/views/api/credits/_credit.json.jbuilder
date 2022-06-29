# frozen_string_literal: true

json.extract! credit, :id, :creditable_id, :creditable_type, :created_at, :updated_at, :plan_id, :hours
if credit.creditable
  json.creditable do
    json.id credit.creditable.id
    json.name credit.creditable.name
  end
end
