class API::WalletController < API::ApiController
  before_action :authenticate_user!

  def my
    @wallet = current_user.wallet
    render :show
  end

  def by_user
    authorize Wallet
    @wallet = Wallet.find_by(user_id: params[:user_id])
    render :show
  end
end
