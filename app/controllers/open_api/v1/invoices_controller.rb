# frozen_string_literal: true

# OpenAPI controller for the invoices
class OpenAPI::V1::InvoicesController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @invoices = Invoice.order(created_at: :desc)
                       .includes(invoicing_profile: :user)
                       .references(:invoicing_profiles)

    @invoices = @invoices.where('invoicing_profiles.user_id = ?', params[:user_id]) if params[:user_id].present?

    return unless params[:page].present?

    @invoices = @invoices.page(params[:page]).per(per_page)
    paginate @invoices, per_page: per_page
  end

  def download
    @invoice = Invoice.find(params[:id])
    send_file File.join(Rails.root, @invoice.file), type: 'application/pdf', disposition: 'inline', filename: @invoice.filename
  end

  private

  def per_page
    params[:per_page] || 20
  end
end
