# frozen_string_literal: true

require_relative 'concerns/subscriptions_filters_concern'

# authorized 3rd party softwares can fetch the subscriptions through the OpenAPI
class OpenAPI::V1::SubscriptionsController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  include OpenAPI::V1::Concerns::SubscriptionsFiltersConcern
  expose_doc

  def index
    @subscriptions = Subscription.order(created_at: :desc)
                                 .includes(:plan, statistic_profile: :user)
                                 .references(:statistic_profile, :plan)

    @subscriptions = filter_by_after(@subscriptions, params)
    @subscriptions = filter_by_before(@subscriptions, params)
    @subscriptions = filter_by_plan(@subscriptions, params)
    @subscriptions = filter_by_user(@subscriptions, params)

    @subscriptions = @subscriptions.page(page).per(per_page)
    paginate @subscriptions, per_page: per_page
  end

  private

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 20
  end
end
