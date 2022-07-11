# frozen_string_literal: true

# Provides helper methods for Availability resources and properties
class Availabilities::AvailabilitiesService

  def initialize(current_user)
    @current_user = current_user
    @maximum_visibility = {
      year: Setting.get('visibility_yearly').to_i.months.since,
      other: Setting.get('visibility_others').to_i.months.since
    }
    @service = Availabilities::StatusService.new(current_user&.role)
  end

  # list all slots for the given machine, with visibility relative to the given user
  def machines(machine, user, window)
    availabilities = availabilities(machine.availabilities, 'machines', user, window[:start], window[:end])

    availabilities.map(&:slots).flatten.map { |s| @service.slot_reserved_status(s, user, machine) }
  end

  # list all slots for the given space, with visibility relative to the given user
  def spaces(space, user, window)
    availabilities = availabilities(space.availabilities, 'space', user, window[:start], window[:end])

    availabilities.map(&:slots).flatten.map { |s| @service.slot_reserved_status(s, user, space) }
  end

  # list all slots for the given training, with visibility relative to the given user
  def trainings(trainings, user, window)
    tr_availabilities = Availability.includes('trainings_availabilities')
                                    .where('trainings_availabilities.training_id': trainings.map(&:id))
    availabilities = availabilities(tr_availabilities, 'training', user, window[:start], window[:end])

    availabilities.map(&:slots).flatten.map { |s| @service.slot_reserved_status(s, user, trainings) }
  end

  private

  def subscription_year?(user)
    user&.subscription && user.subscription.plan.interval == 'year' && user.subscription.expired_at >= DateTime.current
  end

  # members must have validated at least 1 training and must have a valid yearly subscription to view
  # the trainings further in the futur. This is used to prevent users with a rolling subscription to take
  # their first training in a very long delay.
  def show_more_trainings?(user)
    user.trainings.size.positive? && subscription_year?(user)
  end

  def availabilities(availabilities, type, user, range_start, range_end)
    # who made the request?
    # 1) an admin (he can see all availabilities from 1 month ago to anytime in the future)
    if @current_user&.admin? || @current_user&.manager?
      window_start = [range_start, 1.month.ago].max
      availabilities.includes(:tags, :plans)
                    .where('start_at <= ? AND end_at >= ? AND available_type = ?', range_end, window_start, type)
                    .where(lock: false)
    # 2) an user (he cannot see past availabilities neither those further than 1 (or 3) months in the future)
    else
      end_at = @maximum_visibility[:other]
      end_at = @maximum_visibility[:year] if subscription_year?(user) && type != 'training'
      end_at = @maximum_visibility[:year] if show_more_trainings?(user) && type == 'training'
      window_end = [end_at, range_end].min
      window_start = [range_start, DateTime.current].max
      availabilities.includes(:tags, :plans)
                    .where('start_at < ? AND end_at > ? AND available_type = ?', window_end, window_start, type)
                    .where('availability_tags.tag_id' => user.tag_ids.concat([nil]))
                    .where(lock: false)
    end
  end
end
