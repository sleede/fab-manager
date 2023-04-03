# frozen_string_literal: true

# API Controller for resources of type Availability
class API::AvailabilitiesController < API::APIController
  before_action :authenticate_user!, except: [:public]
  before_action :set_availability, only: %i[show update reservations lock]
  before_action :set_operator_role, only: %i[machine spaces trainings]
  before_action :set_customer, only: %i[machine spaces trainings]
  respond_to :json

  def index
    authorize Availability
    display_window = window
    service = Availabilities::AvailabilitiesService.new(@current_user, 'availability')
    machine_ids = params[:m] || []
    @availabilities = service.index(display_window,
                                    { machines: machine_ids, spaces: params[:s], trainings: params[:t] },
                                    events: (params[:evt] && params[:evt] == 'true'))
    @availabilities = filter_availabilites(@availabilities)
  end

  def public
    display_window = window

    machine_ids = params[:m] || []
    service = Availabilities::PublicAvailabilitiesService.new(current_user)
    @availabilities = service.public_availabilities(
      display_window,
      { machines: machine_ids, spaces: params[:s], trainings: params[:t] },
      events: (params[:evt] && params[:evt] == 'true')
    )
    @user = current_user

    @title_filter = { machine_ids: machine_ids.map(&:to_i) }
    @availabilities = filter_availabilites(@availabilities)
  end

  def show
    authorize Availability
  end

  def create
    authorize Availability
    @availability = Availability.new(availability_params)
    if @availability.save
      service = Availabilities::CreateAvailabilitiesService.new
      service.create(@availability, params[:availability][:occurrences])
      render :show, status: :created, location: @availability
    else
      render json: @availability.errors, status: :unprocessable_entity
    end
  end

  # This endpoint is used to remove a machine or a plan from the given availability
  def update
    authorize Availability
    if @availability.update(availability_params)
      render :show, status: :ok, location: @availability
    else
      render json: @availability.errors, status: :unprocessable_entity
    end
  end

  def destroy
    authorize Availability
    service = Availabilities::DeleteAvailabilitiesService.new
    res = service.delete(params[:id], params[:mode])
    if res.all? { |r| r[:status] }
      render json: { deleted: res.length, details: res }, status: :ok
    else
      render json: { total: res.length, deleted: res.select { |r| r[:status] }.length, details: res }, status: :unprocessable_entity
    end
  end

  def machine
    service = Availabilities::AvailabilitiesService.new(current_user)
    @machine = Machine.friendly.find(params[:machine_id])
    @slots = service.machines([@machine], @customer, window)
  end

  def trainings
    service = Availabilities::AvailabilitiesService.new(current_user)
    @trainings = if params[:training_id].is_number? || (params[:training_id].length.positive? && params[:training_id] != 'all')
                   [Training.friendly.find(params[:training_id])]
                 else
                   Training.all
                 end
    @slots = service.trainings(@trainings, @customer, window)
  end

  def spaces
    service = Availabilities::AvailabilitiesService.new(current_user)
    @space = Space.friendly.find(params[:space_id])
    @slots = service.spaces([@space], @customer, window)
  end

  def reservations
    authorize Availability
    @slots_reservations = @availability.slots_reservations
                                       .includes(:slot, reservation: [statistic_profile: [user: [:profile]]])
                                       .order('slots.start_at ASC')
  end

  def export_availabilities
    authorize :export

    export = Export.where(category: 'availabilities', export_type: 'index')
                   .where('created_at > ?', Availability.maximum('updated_at')).last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new(category: 'availabilities', export_type: 'index', user: current_user)
      if @export.save
        render json: { export_id: @export.id }, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file Rails.root.join(export.file),
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    end
  end

  def lock
    authorize @availability
    if @availability.update(lock: lock_params)
      render :show, status: :ok, location: @availability
    else
      render json: @availability.errors, status: :unprocessable_entity
    end
  end

  private

  def window
    start_date = ActiveSupport::TimeZone[params[:timezone]]&.parse(params[:start])
    end_date = ActiveSupport::TimeZone[params[:timezone]]&.parse(params[:end])&.end_of_day
    { start: start_date, end: end_date }
  end

  def set_customer
    @customer = if params[:member_id]
                  User.find(params[:member_id])
                else
                  current_user
                end
  end

  def set_operator_role
    @operator_role = current_user.role
  end

  def set_availability
    @availability = Availability.find(params[:id])
  end

  def availability_params
    params.require(:availability).permit(:start_at, :end_at, :available_type, :machine_ids, :training_ids, :nb_total_places,
                                         :is_recurrent, :period, :nb_periods, :end_date, :slot_duration,
                                         machine_ids: [], training_ids: [], space_ids: [], tag_ids: [], plan_ids: [],
                                         machines_attributes: %i[id _destroy], plans_attributes: %i[id _destroy])
  end

  def lock_params
    params.require(:lock)
  end

  def filter_availabilites(availabilities)
    availabilities_filterd = availabilities
    availabilities_filterd = availabilities.delete_if(&method(:remove_full?)) if params[:dispo] == 'false'

    availabilities_filterd = availabilities.delete_if(&method(:remove_empty?)) if params[:reserved] == 'true'

    availabilities_filterd
  end

  def remove_full?(availability)
    availability.try(:full?) && availability.full?
  end

  def remove_empty?(availability)
    availability.try(:empty?) && availability.empty?
  end
end
