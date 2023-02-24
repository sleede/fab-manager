# frozen_string_literal: true

# API Controller for resources of type StatisticProfilePrepaidPack
class API::UserPacksController < API::APIController
  before_action :authenticate_user!

  def index
    @user_packs = PrepaidPackService.user_packs(user, item)

    @history = params[:history] == 'true'
    @user_packs = @user_packs.includes(:prepaid_pack_reservations) if @history
  end

  private

  def user
    return User.find(params[:user_id]) if current_user.privileged?

    current_user
  end

  def item
    return nil if params[:priceable_type].nil?

    params[:priceable_type].classify.constantize.find(params[:priceable_id])
  end
end
