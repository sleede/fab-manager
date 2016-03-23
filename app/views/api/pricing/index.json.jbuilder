json.array!(@group_pricing) do |group|
  json.extract! group, :id, :name
  json.plans group.plans do |p|
    json.partial! 'api/shared/plan', plan: p
  end
  json.trainings_pricings group.trainings_pricings do |p|
    json.amount p.amount ? (p.amount / 100.0) : 0
    json.training_id p.training_id
  end
  json.machines_prices do
    group.machines_prices.group_by(&:priceable_id).each do |machine_id, prices|
      json.machine_id machine_id
      json.not_subscribe_amount prices.find { |price| price.plan_id.nil? }.amount / 100.0
      json.amount_by_plan prices.select { |price| price.plan_id } do |price|
        json.plan_id price.plan_id
        json.amount price.amount / 100.0
      end
    end
  end
end
