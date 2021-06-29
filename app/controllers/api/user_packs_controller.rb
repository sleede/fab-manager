# frozen_string_literal: true

# API Controller for resources of type StatisticProfilePrepaidPack
class UserPacksController < API::ApiController
  before_action :authenticate_user!

  def index
    @user_packs = PrepaidPackService.user_packs(user, item)
  end

  private

  def user
    return User.find(params[:user_id]) if current_user.privileged?

    current_user
  end

  def item
    params[:priceable_type].classify.constantize.find(params[:priceable_id])
  end
end
