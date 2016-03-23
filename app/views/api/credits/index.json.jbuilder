json.array!(@credits) do |credit|
  json.extract! credit, :id, :creditable_id, :creditable_type, :plan_id, :hours
  json.creditable do
    json.id credit.creditable.id
    json.name credit.creditable.name
  end if credit.creditable.present?
  json.url credit_url(credit, format: :json)
end
