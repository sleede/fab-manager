# frozen_string_literal: true

# Provides helper methods for Availability resources and properties
class Availabilities::AvailabilitiesService

  def initialize(current_user, maximum_visibility = {})
    @current_user = current_user
    @maximum_visibility = maximum_visibility
    @service = Availabilities::StatusService.new(current_user.admin? ? 'admin' : 'user')
  end

  # list all slots for the given machine, with reservations info, relatives to the given user
  def machines(machine_id, user)
    machine = Machine.friendly.find(machine_id)
    reservations = reservations(machine, user)
    availabilities = availabilities(machine, 'machines', user)

    slots = []
    availabilities.each do |a|
      slot_duration = a.slot_duration || ApplicationHelper::SLOT_DURATION
      ((a.end_at - a.start_at) / slot_duration.minutes).to_i.times do |i|
        next unless (a.start_at + (i * slot_duration).minutes) > DateTime.current || user.admin?

        slot = Slot.new(
          start_at: a.start_at + (i * slot_duration).minutes,
          end_at: a.start_at + (i * slot_duration).minutes + slot_duration.minutes,
          availability_id: a.id,
          availability: a,
          machine: machine,
          title: ''
        )
        slot = @service.machine_reserved_status(slot, reservations, @current_user)
        slots << slot
      end
    end
    slots
  end

  # list all slots for the given space, with reservations info, relatives to the given user
  def spaces(space_id, user)
    space = Space.friendly.find(space_id)
    reservations = reservations(space, user)
    availabilities = availabilities(space, 'space', user)

    slots = []
    availabilities.each do |a|
      slot_duration = a.slot_duration || ApplicationHelper::SLOT_DURATION
      ((a.end_at - a.start_at) / slot_duration.minutes).to_i.times do |i|
        next unless (a.start_at + (i * slot_duration).minutes) > DateTime.current || user.admin?

        slot = Slot.new(
          start_at: a.start_at + (i * slot_duration).minutes,
          end_at: a.start_at + (i * slot_duration).minutes + slot_duration.minutes,
          availability_id: a.id,
          availability: a,
          space: space,
          title: ''
        )
        slot = @service.space_reserved_status(slot, reservations, user)
        slots << slot
      end
    end
    slots.each do |s|
      s.title = I18n.t('availabilities.not_available') if s.complete? && !s.is_reserved
    end
    slots
  end

  # list all slots for the given training, with reservations info, relatives to the given user
  def trainings(training_id, user)
    # first, we get the already-made reservations
    reservations = user.reservations.where("reservable_type = 'Training'")
    reservations = reservations.where('reservable_id = :id', id: training_id.to_i) if training_id.is_number?
    reservations = reservations.joins(:slots).where('slots.start_at > ?', @current_user.admin? ? 1.month.ago : DateTime.current)

    # visible availabilities depends on multiple parameters
    availabilities = training_availabilities(training_id, user)

    # finally, we merge the availabilities with the reservations
    availabilities.each do |a|
      a = @service.training_event_reserved_status(a, reservations, user)
    end
  end

  private

  def subscription_year?(user)
    user.subscription && user.subscription.plan.interval == 'year' && user.subscription.expired_at >= DateTime.current
  end

  # member must have validated at least 1 training and must have a valid yearly subscription.
  def show_extended_slots?(user)
    user.trainings.size.positive? && subscription_year?(user)
  end

  def reservations(reservable, user)
    Reservation.where('reservable_type = ? and reservable_id = ?', reservable.class.name, reservable.id)
               .includes(:slots, statistic_profile: [user: [:profile]])
               .references(:slots, :user)
               .where('slots.start_at > ?', user.admin? ? 1.month.ago : DateTime.current)
  end

  def availabilities(reservable, type, user)
    if user.admin? || user.manager?
      reservable.availabilities
                .includes(:tags)
                .where('end_at > ? AND available_type = ?', 1.month.ago, type)
                .where(lock: false)
    else
      end_at = @maximum_visibility[:other]
      end_at = @maximum_visibility[:year] if subscription_year?(user)
      reservable.availabilities
                .includes(:tags)
                .where('end_at > ? AND end_at < ? AND available_type = ?', DateTime.current, end_at, type)
                .where('availability_tags.tag_id' => user.tag_ids.concat([nil]))
                .where(lock: false)
    end
  end

  def training_availabilities(training_id, user)
    availabilities = if training_id.is_number? || (training_id.length.positive? && training_id != 'all')
                       Training.friendly.find(training_id).availabilities
                     else
                       Availability.trainings
                     end

    # who made the request?
    # 1) an admin (he can see all availabilities of 1 month ago and future)
    if @current_user.admin?
      availabilities.includes(:tags, :slots, trainings: [:machines])
                    .where('availabilities.start_at > ?', 1.month.ago)
                    .where(lock: false)
    # 2) an user (he cannot see availabilities further than 1 (or 3) months)
    else
      end_at = @maximum_visibility[:other]
      end_at = @maximum_visibility[:year] if show_extended_slots?(user)
      availabilities.includes(:tags, :slots, :availability_tags, trainings: [:machines])
                    .where('availabilities.start_at > ? AND availabilities.start_at < ?', DateTime.current, end_at)
                    .where('availability_tags.tag_id' => user.tag_ids.concat([nil]))
                    .where(lock: false)
    end
  end
end
