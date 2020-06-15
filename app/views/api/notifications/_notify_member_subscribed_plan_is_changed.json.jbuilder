# frozen_string_literal: true

# @deprecated
# <b>DEPRECATED:</b> Feature removed in v1 (87dd9ba0 2015-06-04)
json.title notification.notification_type
json.description t('.you_have_changed_your_subscription_to_PLAN_html',
                   PLAN: notification.attached_object.plan.name)

