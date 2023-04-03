# frozen_string_literal: true

require_relative 'concerns/accountings_filters_concern'

# authorized 3rd party softwares can fetch the accounting lines through the OpenAPI
class OpenAPI::V1::AccountingController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  include OpenAPI::V1::Concerns::AccountingsFiltersConcern
  expose_doc

  def index
    @codes = {
      card: Setting.get('accounting_payment_card_code'),
      wallet: Setting.get('accounting_payment_wallet_code'),
      other: Setting.get('accounting_payment_other_code')
    }

    @lines = AccountingLine.order(date: :desc)
                           .includes(:invoicing_profile, invoice: :payment_gateway_object)

    @lines = filter_by_after(@lines, params)
    @lines = filter_by_before(@lines, params)
    @lines = filter_by_invoice(@lines, params)
    @lines = filter_by_line_type(@lines, params)

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
