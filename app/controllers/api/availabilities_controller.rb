class API::AvailabilitiesController < API::ApiController
  include FablabConfiguration

  before_action :authenticate_user!, except: [:public]
  before_action :set_availability, only: [:show, :update, :destroy, :reservations, :lock]
  before_action :define_max_visibility, only: [:machine, :trainings, :spaces]
  respond_to :json

  def index
    authorize Availability
    start_date = ActiveSupport::TimeZone[params[:timezone]].parse(params[:start])
    end_date = ActiveSupport::TimeZone[params[:timezone]].parse(params[:end]).end_of_day
    @availabilities = Availability.includes(:machines, :tags, :trainings, :spaces).where.not(available_type: 'event')
                                  .where('start_at >= ? AND end_at <= ?', start_date, end_date)

    if fablab_spaces_deactivated?
      @availabilities = @availabilities.where.not(available_type: 'space')
    end
  end

  def public
    start_date = ActiveSupport::TimeZone[params[:timezone]].parse(params[:start])
    end_date = ActiveSupport::TimeZone[params[:timezone]].parse(params[:end]).end_of_day
    @reservations = Reservation.includes(:slots, user: [:profile]).references(:slots, :user)
                        .where('slots.start_at >= ? AND slots.end_at <= ?', start_date, end_date)

    # request for 1 single day
    if in_same_day(start_date, end_date)
      # trainings, events
      @training_and_event_availabilities = Availability.includes(:tags, :trainings, :event, :slots).where(available_type: %w(training event))
                                    .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                    .where(lock: false)
      # machines
      @machine_availabilities = Availability.includes(:tags, :machines).where(available_type: 'machines')
                                    .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                    .where(lock: false)
      @machine_slots = []
      @machine_availabilities.each do |a|
        a.machines.each do |machine|
          if params[:m] and params[:m].include?(machine.id.to_s)
            ((a.end_at - a.start_at)/ApplicationHelper::SLOT_DURATION.minutes).to_i.times do |i|
              slot = Slot.new(
                  start_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes,
                  end_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes + ApplicationHelper::SLOT_DURATION.minutes,
                  availability_id: a.id,
                  availability: a,
                  machine: machine,
                  title: machine.name
              )
              slot = verify_machine_is_reserved(slot, @reservations, current_user, '')
              @machine_slots << slot
            end
          end
        end
      end

      # spaces
      @space_availabilities = Availability.includes(:tags, :spaces).where(available_type: 'space')
                                          .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                          .where(lock: false)

      if params[:s]
        @space_availabilities.where(available_id: params[:s])
      end

      @space_slots = []
      @space_availabilities.each do |a|
        space = a.spaces.first
        ((a.end_at - a.start_at)/ApplicationHelper::SLOT_DURATION.minutes).to_i.times do |i|
          if (a.start_at + (i * ApplicationHelper::SLOT_DURATION).minutes) > Time.now
            slot = Slot.new(
                start_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes,
                end_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes + ApplicationHelper::SLOT_DURATION.minutes,
                availability_id: a.id,
                availability: a,
                space: space,
                title: space.name
            )
            slot = verify_space_is_reserved(slot, @reservations, current_user, '')
            @space_slots << slot
          end
        end
      end
      @availabilities = [].concat(@training_and_event_availabilities).concat(@machine_slots).concat(@space_slots)

    # request for many days (week or month)
    else
      @availabilities = Availability.includes(:tags, :machines, :trainings, :spaces, :event, :slots)
                                    .where('start_at >= ? AND end_at <= ?', start_date, end_date)
                                    .where(lock: false)
      @availabilities.each do |a|
        if a.available_type == 'training' or a.available_type == 'event'
          a = verify_training_event_is_reserved(a, @reservations, current_user)
        elsif a.available_type == 'space'
          a.is_reserved = is_reserved_availability(a, current_user)
        end
      end
    end
    machine_ids = params[:m] || []
    @title_filter = {machine_ids: machine_ids.map(&:to_i)}
    @availabilities = filter_availabilites(@availabilities)
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
    @machine = Machine.friendly.find(params[:machine_id])
    @slots = []
    @reservations = Reservation.where('reservable_type = ? and reservable_id = ?', @machine.class.to_s, @machine.id).includes(:slots, user: [:profile]).references(:slots, :user).where('slots.start_at > ?', Time.now)
    if @user.is_admin?
      @availabilities = @machine.availabilities.includes(:tags)
                            .where("end_at > ? AND available_type = 'machines'", Time.now)
                            .where(lock: false)
    else
      end_at = @visi_max_other
      end_at = @visi_max_year if is_subscription_year(@user)
      @availabilities = @machine.availabilities.includes(:tags).where("end_at > ? AND end_at < ? AND available_type = 'machines'", Time.now, end_at)
                            .where('availability_tags.tag_id' => @user.tag_ids.concat([nil]))
                            .where(lock: false)
    end
    @availabilities.each do |a|
      ((a.end_at - a.start_at)/ApplicationHelper::SLOT_DURATION.minutes).to_i.times do |i|
        if (a.start_at + (i * ApplicationHelper::SLOT_DURATION).minutes) > Time.now
          slot = Slot.new(
              start_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes,
              end_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes + ApplicationHelper::SLOT_DURATION.minutes,
              availability_id: a.id,
              availability: a,
              machine: @machine,
              title: ''
          )
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

    # first, we get the already-made reservations
    @reservations = @user.reservations.where("reservable_type = 'Training'")
    @reservations = @reservations.where('reservable_id = :id', id: params[:training_id].to_i) if params[:training_id].is_number?
    @reservations = @reservations.joins(:slots).where('slots.start_at > ?', Time.now)

    # what is requested?
    # 1) a single training
    if params[:training_id].is_number? or (params[:training_id].length > 0 and params[:training_id] != 'all')
      @availabilities = Training.friendly.find(params[:training_id]).availabilities
    # 2) all trainings
    else
      @availabilities = Availability.trainings
    end

    # who made the request?
    # 1) an admin (he can see all future availabilities)
    if current_user.is_admin?
      @availabilities = @availabilities.includes(:tags, :slots, trainings: [:machines])
                            .where('availabilities.start_at > ?', Time.now)
                            .where(lock: false)
    # 2) an user (he cannot see availabilities further than 1 (or 3) months)
    else
      end_at = @visi_max_year
      end_at = @visi_max_year if can_show_slot_plus_three_months(@user)
      @availabilities = @availabilities.includes(:tags, :slots, :availability_tags, trainings: [:machines])
                            .where('availabilities.start_at > ? AND availabilities.start_at < ?', Time.now, end_at)
                            .where('availability_tags.tag_id' => @user.tag_ids.concat([nil]))
                            .where(lock: false)
    end

    # finally, we merge the availabilities with the reservations
    @availabilities.each do |a|
      a = verify_training_event_is_reserved(a, @reservations, @user)
    end
  end

  def spaces
    if params[:member_id]
      @user = User.find(params[:member_id])
    else
      @user = current_user
    end
    @current_user_role = current_user.is_admin? ? 'admin' : 'user'
    @space = Space.friendly.find(params[:space_id])
    @slots = []
    @reservations = Reservation.where('reservable_type = ? and reservable_id = ?', @space.class.to_s, @space.id)
                        .includes(:slots, user: [:profile]).references(:slots, :user)
                        .where('slots.start_at > ?', Time.now)
    if current_user.is_admin?
      @availabilities = @space.availabilities.includes(:tags)
                            .where("end_at > ? AND available_type = 'space'", Time.now)
                            .where(lock: false)
    else
      end_at = @visi_max_other
      end_at = @visi_max_year if is_subscription_year(@user)
      @availabilities = @space.availabilities.includes(:tags)
                            .where("end_at > ? AND end_at < ? AND available_type = 'space'", Time.now, end_at)
                            .where('availability_tags.tag_id' => @user.tag_ids.concat([nil]))
                            .where(lock: false)
    end
    @availabilities.each do |a|
      ((a.end_at - a.start_at)/ApplicationHelper::SLOT_DURATION.minutes).to_i.times do |i|
        if (a.start_at + (i * ApplicationHelper::SLOT_DURATION).minutes) > Time.now
          slot = Slot.new(
              start_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes,
              end_at: a.start_at + (i*ApplicationHelper::SLOT_DURATION).minutes + ApplicationHelper::SLOT_DURATION.minutes,
              availability_id: a.id,
              availability: a,
              space: @space,
              title: ''
          )
          slot = verify_space_is_reserved(slot, @reservations, @user, @current_user_role)
          @slots << slot
        end
      end
    end
    @slots.each do |s|
      if s.is_complete? and not s.is_reserved
        s.title = t('availabilities.not_available')
      end
    end
  end

  def reservations
    authorize Availability
    @reservation_slots = @availability.slots.includes(reservations: [user: [:profile]]).order('slots.start_at ASC')
  end

  def export_availabilities
    authorize :export

    export = Export.where({category:'availabilities', export_type: 'index'}).where('created_at > ?', Availability.maximum('updated_at')).last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new({category:'availabilities', export_type: 'index', user: current_user})
      if @export.save
        render json: {export_id: @export.id}, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file File.join(Rails.root, export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
    end
  end

  def lock
    authorize @availability
    if @availability.update_attributes(lock: lock_params)
      render :show, status: :ok, location: @availability
    else
      render json: @availability.errors, status: :unprocessable_entity
    end
  end

  private
    def set_availability
      @availability = Availability.find(params[:id])
    end

    def availability_params
      params.require(:availability).permit(:start_at, :end_at, :available_type, :machine_ids, :training_ids, :nb_total_places, machine_ids: [], training_ids: [], space_ids: [], tag_ids: [],
                                           :machines_attributes => [:id, :_destroy])
    end

    def lock_params
      params.require(:lock)
    end

    def is_reserved_availability(availability, user)
      if user
        reserved_slots = []
        availability.slots.each do |s|
          if s.canceled_at.nil?
            reserved_slots << s
          end
        end
        reserved_slots.map(&:reservations).flatten.map(&:user_id).include? user.id
      else
        false
      end
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
      show_name = (user_role == 'admin' or Setting.find_by(name: 'display_name_enable').value == 'true')
      reservations.each do |r|
        r.slots.each do |s|
          if slot.machine.id == r.reservable_id
            if s.start_at == slot.start_at and s.canceled_at == nil
              slot.id = s.id
              slot.is_reserved = true
              slot.title = "#{slot.machine.name} - #{show_name ? r.user.profile.full_name : t('availabilities.not_available')}"
              slot.can_modify = true if user_role === 'admin'
              slot.reservations.push r
            end
            if s.start_at == slot.start_at and r.user == user and s.canceled_at == nil
              slot.title = "#{slot.machine.name} - #{t('availabilities.i_ve_reserved')}"
              slot.can_modify = true
              slot.is_reserved_by_current_user = true
            end
          end
        end
      end
      slot
    end

    def verify_space_is_reserved(slot, reservations, user, user_role)
      reservations.each do |r|
        r.slots.each do |s|
          if slot.space.id == r.reservable_id
            if s.start_at == slot.start_at and s.canceled_at == nil
              slot.can_modify = true if user_role === 'admin'
              slot.reservations.push r
            end
            if s.start_at == slot.start_at and r.user == user and s.canceled_at == nil
              slot.id = s.id
              slot.title = t('availabilities.i_ve_reserved')
              slot.can_modify = true
              slot.is_reserved = true
            end
          end
        end
      end
      slot
    end

    def verify_training_event_is_reserved(availability, reservations, user)
      reservations.each do |r|
        r.slots.each do |s|
          if ((availability.available_type == 'training' and availability.trainings.first.id == r.reservable_id) or (availability.available_type == 'event' and availability.event.id == r.reservable_id)) and s.start_at == availability.start_at and s.canceled_at == nil
            availability.slot_id = s.id
            if r.user == user
              availability.is_reserved = true
              availability.can_modify = true
            end
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

    def in_same_day(start_date, end_date)
      (end_date.to_date - start_date.to_date).to_i == 1
    end

    def filter_availabilites(availabilities)
      availabilities_filtered = []
      availabilities.to_ary.each do |a|
        # machine slot
        if !a.try(:available_type)
          availabilities_filtered << a
        else
          # training
          if params[:t] and a.available_type == 'training'
            if params[:t].include?(a.trainings.first.id.to_s)
              availabilities_filtered << a
            end
          end
          # space
          if params[:s] and a.available_type == 'space'
            if params[:s].include?(a.spaces.first.id.to_s)
              availabilities_filtered << a
            end
          end
          # machines
          if params[:m] and a.available_type == 'machines'
            if (params[:m].map(&:to_i) & a.machine_ids).any?
              availabilities_filtered << a
            end
          end
          # event
          if params[:evt] and params[:evt] == 'true' and a.available_type == 'event'
            availabilities_filtered << a
          end
        end
      end
      availabilities_filtered.delete_if do |a|
        if params[:dispo] == 'false'
          a.is_reserved or (a.try(:is_completed) and a.is_completed)
        end
      end
    end

  def define_max_visibility
    @visi_max_year = Setting.find_by(name: 'visibility_yearly').value.to_i.months.since
    @visi_max_other = Setting.find_by(name: 'visibility_others').value.to_i.months.since
  end
end
