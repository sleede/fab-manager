json.extract! @credit, :id, :creditable_id, :creditable_type, :created_at, :updated_at, :plan_id, :hours
json.creditable do
  json.id @credit.creditable.id
  json.name @credit.creditable.name
end if @credit.creditable
