# frozen_string_literal: true

# authorized 3rd party softwares can fetch the accounting lines through the OpenAPI
class OpenAPI::V1::AccountingController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @codes = {
      card: Setting.get('accounting_payment_card_code'),
      wallet: Setting.get('accounting_payment_wallet_code'),
      other: Setting.get('accounting_payment_other_code')
    }

    @lines = AccountingLine.order(date: :desc)
                           .includes(:invoicing_profile, invoice: :payment_gateway_object)

    @lines = @lines.where('date >= ?', DateTime.parse(params[:after])) if params[:after].present?
    @lines = @lines.where('date <= ?', DateTime.parse(params[:before])) if params[:before].present?
    @lines = @lines.where(invoice_id: may_array(params[:invoice_id])) if params[:invoice_id].present?
    @lines = @lines.where(line_type: may_array(params[:type])) if params[:type].present?

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
