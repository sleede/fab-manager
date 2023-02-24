# frozen_string_literal: true

# API Controller for resources of type PrepaidPack
# PrepaidPacks are used to provide discounts to users that bought many hours at once
class API::PrepaidPacksController < API::APIController
  include ApplicationHelper

  before_action :authenticate_user!, except: :index
  before_action :set_pack, only: %i[show update destroy]

  def index
    @packs = PrepaidPackService.list(params).order(minutes: :asc)
  end

  def show; end

  def create
    authorize PrepaidPack
    @pack = PrepaidPack.new(pack_params)
    if @pack.save
      render status: :created
    else
      render json: @pack.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    authorize @pack

    if @pack.update(pack_params)
      render status: :ok
    else
      render json: @pack.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pack
    @pack.destroy
    head :no_content
  end

  private

  def set_pack
    @pack = PrepaidPack.find(params[:id])
  end

  def pack_params
    pack_params = params
    pack_params[:pack][:amount] = to_centimes(pack_params[:pack][:amount]) if pack_params[:pack][:amount]
    params.require(:pack).permit(:priceable_id, :priceable_type, :group_id, :amount, :minutes, :validity_count, :validity_interval,
                                 :disabled)
  end
end
