# frozen_string_literal: true

json.page @result[:page]
json.total_pages @result[:total_pages]
json.page_size @result[:page_size]
json.total_count @result[:total_count]
json.data @result[:data] do |order|
  json.extract! order, :id, :statistic_profile_id, :reference, :state, :created_at
  json.total order.total / 100.0 if order.total.present?
  json.paid_total order.paid_total / 100.0 if order.paid_total.present?
  if order&.statistic_profile&.user
    json.user do
      json.id order.statistic_profile.user.id
      json.role order.statistic_profile.user.roles.first.name
      json.name order.statistic_profile.user.profile.full_name
    end
  end
end
