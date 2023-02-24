# frozen_string_literal: true

# Filter the list of subscriptions by the given parameters
module OpenAPI::V1::Concerns::SubscriptionsFiltersConcern
  extend ActiveSupport::Concern

  included do
    # @param subscriptions [ActiveRecord::Relation<Subscription>]
    # @param filters [ActionController::Parameters]
    def filter_by_after(subscriptions, filters)
      return subscriptions if filters[:after].blank?

      subscriptions.where('created_at >= ?', Time.zone.parse(filters[:after]))
    end

    # @param subscriptions [ActiveRecord::Relation<Subscription>]
    # @param filters [ActionController::Parameters]
    def filter_by_before(subscriptions, filters)
      return subscriptions if filters[:before].blank?

      subscriptions.where('created_at <= ?', Time.zone.parse(filters[:before]))
    end

    # @param subscriptions [ActiveRecord::Relation<Subscription>]
    # @param filters [ActionController::Parameters]
    def filter_by_user(subscriptions, filters)
      return subscriptions if filters[:user_id].blank?

      subscriptions.where(statistic_profiles: { user_id: may_array(filters[:user_id]) })
    end

    # @param subscriptions [ActiveRecord::Relation<Subscription>]
    # @param filters [ActionController::Parameters]
    def filter_by_plan(subscriptions, filters)
      return subscriptions if filters[:plan_id].blank?

      subscriptions.where(plan_id: may_array(filters[:plan_id]))
    end
  end
end
