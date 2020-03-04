# frozen_string_literal: true

# API Controller for resources of type Wallet
class API::WalletController < API::ApiController
  before_action :authenticate_user!

  def by_user
    invoicing_profile = InvoicingProfile.find_by(user_id: params[:user_id])
    @wallet = Wallet.find_by(invoicing_profile_id: invoicing_profile.id)
    authorize @wallet
    render :show
  end

  def transactions
    @wallet = Wallet.find(params[:id])
    authorize @wallet
    @wallet_transactions = @wallet.wallet_transactions.includes(:invoice, :invoicing_profile).order(created_at: :desc)
  end

  def credit
    return head 422 if Rails.application.secrets.fablab_without_wallet == 'true'

    @wallet = Wallet.find(credit_params[:id])
    authorize @wallet
    service = WalletService.new(user: current_user, wallet: @wallet)
    transaction = service.credit(credit_params[:amount].to_f)
    if transaction
      service.create_avoir(transaction, credit_params[:avoir_date], credit_params[:avoir_description]) if credit_params[:avoir]
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
