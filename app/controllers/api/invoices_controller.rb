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

  def list
    authorize Invoice

    p = params.require(:query).permit(:number, :customer, :date, :order_by, :page, :size)

    unless p[:page].is_a? Integer
      render json: {error: 'page must be an integer'}, status: :unprocessable_entity
    end

    unless p[:size].is_a? Integer
      render json: {error: 'size must be an integer'}, status: :unprocessable_entity
    end


    direction = (p[:order_by][0] == '-' ? 'DESC' : 'ASC')
    order_key = (p[:order_by][0] == '-' ? p[:order_by][1, p[:order_by].size] : p[:order_by])

    case order_key
      when 'reference'
        order_key = 'invoices.reference'
      when 'date'
        order_key = 'invoices.created_at'
      when 'total'
        order_key = 'invoices.total'
      when 'name'
        order_key = 'profiles.first_name'
      else
        order_key = 'invoices.id'
    end

    @invoices = Invoice.includes(:avoir, :invoiced, invoice_items: [:subscription, :invoice_item], user: [:profile, :trainings])
                .joins(:user => :profile)
                .order("#{order_key} #{direction}")
                .page(p[:page])
                .per(p[:size])

    # ILIKE => PostgreSQL case-insensitive LIKE
    @invoices = @invoices.where('invoices.reference LIKE :search', search: "#{p[:number].to_s}%") if p[:number].size > 0
    @invoices = @invoices.where('profiles.first_name ILIKE :search OR profiles.last_name ILIKE :search', search: "%#{p[:customer]}%") if p[:customer].size > 0
    @invoices = @invoices.where("date_trunc('day', invoices.created_at) = :search", search: "%#{DateTime.iso8601(p[:date]).to_time.to_date.to_s}%") unless p[:date].nil?

    @invoices

  end

  # only for create refund invoices (avoir)
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
