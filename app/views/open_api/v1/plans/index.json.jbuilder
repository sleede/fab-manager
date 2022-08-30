# frozen_string_literal: true

json.plans @plans do |plan|
  json.partial! 'open_api/v1/plans/plan', plan: plan
end
