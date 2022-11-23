# frozen_string_literal: true

# authorized 3rd party softwares can fetch the accounting lines through the OpenAPI
class OpenAPI::V1::AccountingController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @lines = AccountingLine.order(date: :desc)
                           .includes(:invoice)

    @lines = @lines.where('date >= ?', DateTime.parse(params[:after])) if params[:after].present?
    @lines = @lines.where('date <= ?', DateTime.parse(params[:before])) if params[:before].present?
    @lines = @lines.where(invoice_id: may_array(params[:invoice_id])) if params[:invoice_id].present?

    @lines = @lines.page(page).per(per_page)
    paginate @lines, per_page: per_page
  end

  private

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 20
  end
end
