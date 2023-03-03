# frozen_string_literal: true

json.subscriptions @subscriptions do |subscription|
  json.extract! subscription, :id, :created_at, :expiration_date, :canceled_at, :plan_id
  json.user_id subscription.statistic_profile.user_id
end
