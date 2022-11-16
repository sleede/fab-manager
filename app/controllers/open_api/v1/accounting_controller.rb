# frozen_string_literal: true

# OpenAPI controller for the accounting lines
class OpenAPI::V1::AccountingController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @invoices = Invoice.order(created_at: :desc)
                       .includes(invoicing_profile: :user)
                       .references(:invoicing_profiles)

    @invoices = @invoices.where(invoicing_profiles: { user_id: params[:user_id] }) if params[:user_id].present?

    return if params[:page].blank?

    @invoices = @invoices.page(params[:page]).per(per_page)
    paginate @invoices, per_page: per_page
  end

  private

  def per_page
    params[:per_page] || 20
  end
end
