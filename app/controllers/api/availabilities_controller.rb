class API::AvailabilitiesController < API::ApiController
  before_action :authenticate_user!
  before_action :set_availability, only: [:show, :update, :destroy, :reservations]
  respond_to :json

  ## machine availabilities are divided in multiple slots of 60 minutes
  SLOT_DURATION = 60

  def index
    authorize Availability
    @availabilities = Availability.includes(:machines,:tags,:trainings).where.not(available_type: 'event')
  end

  def show
    authorize Availability
  end

  def create
    authorize Availability
    @availability = Availability.new(availability_params)
    if @availability.save
      render :show, status: :created, location: @availability
    else
      render json: @availability.errors, status: :unprocessable_entity
    end
  end

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
    if @availability.safe_destroy
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  def machine
    if params[:member_id]
      @user = User.find(params[:member_id])
    else
      @user = current_user
    end
    @current_user_role = current_user.is_admin? ? 'admin' : 'user'
    @machine = Machine.find(params[:machine_id])
    @slots = []
    @reservations = Reservation.where('reservable_type = ? and reservable_id = ?', @machine.class.to_s, @machine.id).includes(:slots, user: [:profile]).references(:slots, :user).where('slots.start_at > ?', Time.now)
    if @user.is_admin?
      @availabilities = @machine.availabilities.includes(:tags).where("end_at > ? AND available_type = 'machines'", Time.now)
    else
      end_at = 1.month.since
      end_at = 3.months.since if is_subscription_year(@user)
      @availabilities = @machine.availabilities.includes(:tags).where("end_at > ? AND end_at < ? AND available_type = 'machines'", Time.now, end_at).where('availability_tags.tag_id' => @user.tag_ids.concat([nil]))
    end
    @availabilities.each do |a|
      ((a.end_at - a.start_at)/SLOT_DURATION.minutes).to_i.times do |i|
        if (a.start_at + (i * SLOT_DURATION).minutes) > Time.now
          slot = Slot.new(start_at: a.start_at + (i*SLOT_DURATION).minutes, end_at: a.start_at + (i*SLOT_DURATION).minutes + SLOT_DURATION.minutes, availability_id: a.id, availability: a, machine: @machine, title: '')
          slot = verify_machine_is_reserved(slot, @reservations, current_user, @current_user_role)
          @slots << slot
        end
      end
    end
  end

  def trainings
    if params[:member_id]
      @user = User.find(params[:member_id])
    else
      @user = current_user
    end
    @slots = []
    @reservations = @user.reservations.includes(:slots).references(:slots).where("reservable_type = 'Training' AND slots.start_at > ?", Time.now)
    if @user.is_admin?
      @availabilities = Availability.includes(:tags, :slots, trainings: [:machines]).trainings.where('availabilities.start_at > ?', Time.now)
    else
      end_at = 1.month.since
      end_at = 3.months.since if can_show_slot_plus_three_months(@user)
      @availabilities = Availability.includes(:tags, :slots, trainings: [:machines]).trainings.where('start_at > ? AND start_at < ?', Time.now, end_at).where('availability_tags.tag_id' => @user.tag_ids.concat([nil]))
    end
    @availabilities.each do |a|
      a = verify_training_is_reserved(a, @reservations)
    end
  end

  def reservations
    authorize Availability
    @reservation_slots = @availability.slots.includes(reservation: [user: [:profile]]).order('slots.start_at ASC')
  end

  private
    def set_availability
      @availability = Availability.find(params[:id])
    end

    def availability_params
      params.require(:availability).permit(:start_at, :end_at, :available_type, :machine_ids, :training_ids, :nb_total_places, machine_ids: [], training_ids: [], tag_ids: [],
                                           :machines_attributes => [:id, :_destroy])
    end

    def is_reserved(start_at, reservations)
      is_reserved = false
      reservations.each do |r|
        r.slots.each do |s|
          is_reserved = true if s.start_at == start_at
        end
      end
      is_reserved
    end

    def verify_machine_is_reserved(slot, reservations, user, user_role)
      reservations.each do |r|
        r.slots.each do |s|
          if s.start_at == slot.start_at and s.canceled_at == nil
            slot.id = s.id
            slot.is_reserved = true
            slot.title = t('availabilities.not_available')
            slot.can_modify = true if user_role === 'admin'
            slot.reservation = r
          end
          if s.start_at == slot.start_at and r.user == user and s.canceled_at == nil
            slot.title = t('availabilities.i_ve_reserved')
            slot.can_modify = true
            slot.is_reserved_by_current_user = true
          end
        end
      end
      slot
    end

    def verify_training_is_reserved(availability, reservations)
      user = current_user
      reservations.each do |r|
        r.slots.each do |s|
          if s.start_at == availability.start_at and s.canceled_at == nil and availability.trainings.first.id == r.reservable_id
            availability.slot_id = s.id
            availability.is_reserved = true
            availability.can_modify = true if r.user == user
          end
        end
      end
      availability
    end

    def can_show_slot_plus_three_months(user)
      # member must have validated at least 1 training and must have a valid yearly subscription.
      user.trainings.size > 0 and is_subscription_year(user)
    end

    def is_subscription_year(user)
      user.subscription and user.subscription.plan.interval == 'year' and user.subscription.expired_at >= Time.now
    end
end
