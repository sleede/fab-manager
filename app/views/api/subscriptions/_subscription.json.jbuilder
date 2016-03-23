json.extract! subscription, :id, :plan_id
json.expired_at subscription.expired_at.iso8601
json.canceled_at subscription.canceled_at.iso8601 if subscription.canceled_at
json.stripe subscription.stp_subscription_id.present?
json.plan do
  json.partial! 'api/shared/plan', plan: subscription.plan
end
