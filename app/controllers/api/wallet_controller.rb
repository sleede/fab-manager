class API::WalletController < API::ApiController
  before_action :authenticate_user!

  def by_user
    @wallet = Wallet.find_by(user_id: params[:user_id])
    authorize @wallet
    render :show
  end

  def transactions
    @wallet = Wallet.find(params[:id])
    authorize @wallet
    @wallet_transactions = @wallet.wallet_transactions.includes(:invoice, user: [:profile]).order(created_at: :desc)
  end

  def credit
    @wallet = Wallet.find(credit_params[:id])
    authorize @wallet
    service = WalletService.new(user: current_user, wallet: @wallet)
    transaction = service.credit(credit_params[:amount].to_f)
    if transaction
      if credit_params[:avoir]
        service.create_avoir(transaction, credit_params[:avoir_date], credit_params[:avoir_description])
      end
      render :show
    else
      head 422
    end
  end

  private
  def credit_params
    params.permit(:id, :amount, :avoir, :avoir_date, :avoir_description)
  end
end
