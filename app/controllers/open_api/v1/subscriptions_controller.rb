# frozen_string_literal: true

# authorized 3rd party softwares can fetch the subscriptions through the OpenAPI
class OpenAPI::V1::SubscriptionsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @subscriptions = Subscription.order(created_at: :desc)
                                 .includes(:plan, statistic_profile: :user)
                                 .references(:statistic_profile, :plan)

    @subscriptions = @subscriptions.where('created_at >= ?', Time.zone.parse(params[:after])) if params[:after].present?
    @subscriptions = @subscriptions.where('created_at <= ?', Time.zone.parse(params[:before])) if params[:before].present?
    @subscriptions = @subscriptions.where(plan_id: may_array(params[:plan_id])) if params[:plan_id].present?
    @subscriptions = @subscriptions.where(statistic_profiles: { user_id: may_array(params[:user_id]) }) if params[:user_id].present?

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
