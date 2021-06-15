# frozen_string_literal: true

# API Controller for resources of type Training
class API::TrainingsController < API::ApiController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_training, only: %i[update destroy]

  def index
    @requested_attributes = params[:requested_attributes]
    @trainings = policy_scope(Training)
    @trainings = @trainings.where(public_page: true) if params[:public_page]

    return unless attribute_requested?(@requested_attributes, 'availabilities')

    @trainings = @trainings.includes(availabilities: [slots: [reservation: [user: %i[profile trainings]]]])
                           .order('availabilities.start_at DESC')
  end

  def show
    @training = Training.friendly.find(params[:id])
  end

  def create
    authorize Training
    @training = Training.new(training_params)
    if @training.save
      render :show, status: :created, location: @training
    else
      render json: @training.errors, status: :unprocessable_entity
    end
  end

  def update
    authorize Training
    if params[:training][:users].present?
      members = User.where(id: valid_training_params[:users])
      members.each do |m|
        m.trainings << @training
      end

      head :no_content
    elsif current_user.admin? && @training.update(training_params)
      # only admins can fully update a training, not managers
      render :show, status: :ok, location: @training
    else
      render json: @training.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @training
    @training.destroy
    head :no_content
  end

  def availabilities
    authorize Training
    @training = Training.find(params[:id])
    @availabilities = @training.availabilities
                               .includes(slots: { reservations: { statistic_profile: [:trainings, user: [:profile]] } })
                               .where('slots.canceled_at': nil)
                               .order('availabilities.start_at DESC')
  end

  private

  def set_training
    @training = Training.find(params[:id])
  end

  def valid_training_params
    params.require(:training).permit(:id, users: [])
  end

  def training_params
    params.require(:training)
          .permit(:id, :name, :description, :machine_ids, :plan_ids, :nb_total_places, :public_page, :disabled,
                  training_image_attributes: [:attachment], machine_ids: [], plan_ids: [])
  end
end
