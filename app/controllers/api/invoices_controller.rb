class API::InvoicesController < API::ApiController
  before_action :authenticate_user!
  before_action :set_invoice, only: [:show, :download]

  def index
    authorize Invoice
    @invoices = Invoice.includes(:avoir, :invoiced, invoice_items: [:subscription, :invoice_item], user: [:profile, :trainings]).all.order('reference DESC')
  end

  def download
    authorize @invoice
    send_file File.join(Rails.root, @invoice.file), :type => 'application/pdf', :disposition => 'attachment'
  end

  # only for create avoir
  def create
    authorize Invoice
    invoice = Invoice.only_invoice.find(avoir_params[:invoice_id])
    @avoir = invoice.build_avoir(avoir_params)
    if @avoir.save
      render :avoir, status: :created
    else
      render json: @avoir.errors, status: :unprocessable_entity
    end
  end

  private
    def avoir_params
      params.require(:avoir).permit(:invoice_id, :avoir_date, :avoir_mode, :subscription_to_expire, :description, :invoice_items_ids => [])
    end

    def set_invoice
      @invoice = Invoice.find(params[:id])
    end
end
