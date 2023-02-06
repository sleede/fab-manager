# frozen_string_literal: true

json.data @subscriptions do |subscription|
  json.extract! subscription, :id, :created_at, :expiration_date, :canceled_at, :plan_id
  json.user_id subscription.statistic_profile.user_id
end
json.total_pages @pageination_meta[:total_pages]
json.total_count @pageination_meta[:total_count]
json.page @pageination_meta[:page]
json.page_siez @pageination_meta[:page_size]
