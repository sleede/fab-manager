class OpenAPI::V1::InvoicesController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    @invoices = Invoice.order(created_at: :desc)

    if params[:user_id].present?
      @invoices = @invoices.where(user_id: params[:user_id])
    end

    if params[:page].present?
      @invoices = @invoices.page(params[:page]).per(per_page)
      paginate @invoices, per_page: per_page
    end
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
