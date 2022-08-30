# frozen_string_literal: true

json.plan_categories @plans_categories do |category|
  json.extract! category, :id, :name, :weight, :description, :updated_at, :created_at
end
