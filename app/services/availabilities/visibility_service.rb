# frozen_string_literal: true

# Return the maximum available visibility for a user
class Availabilities::VisibilityService
  def initialize
    @maximum_visibility = {
      year: Setting.get('visibility_yearly').to_i.months.since,
      other: Setting.get('visibility_others').to_i.months.since
    }
    @minimum_visibility = Setting.get('reservation_deadline').to_i.minutes.since
  end

  # @param user [User,NilClass]
  # @param available_type [String] 'training', 'space', 'machine' or 'event'
  # @param range_start [ActiveSupport::TimeWithZone]
  # @param range_end [ActiveSupport::TimeWithZone]
  # @return [Array<ActiveSupport::TimeWithZone,Date,Time>] as: [start,end]
  def visibility(user, available_type, range_start, range_end)
    if user&.privileged?
      window_start = [range_start, 1.month.ago].max
      window_end = range_end
    else
      end_at = @maximum_visibility[:other]
      end_at = @maximum_visibility[:year] if subscription_year?(user) && available_type != 'training'
      end_at = @maximum_visibility[:year] if show_more_trainings?(user) && available_type == 'training'
      end_at = subscription_visibility(user, available_type) || end_at
      window_end = [end_at, range_end].min
      window_start = [range_start, @minimum_visibility].max
    end
    [window_start, window_end]
  end

  private

  # @param user [User,NilClass]
  def subscription_year?(user)
    user&.subscribed_plan &&
      (user&.subscribed_plan&.interval == 'year' ||
        (user&.subscribed_plan&.interval == 'month' && user.subscribed_plan.interval_count >= 12))
  end

  # @param user [User,NilClass]
  # @param available_type [String] 'training', 'space', 'machine' or 'event'
  # @return [Time,NilClass]
  def subscription_visibility(user, available_type)
    return nil unless user&.subscribed_plan
    return nil unless available_type == 'machine'

    machines = user&.subscribed_plan&.machines_visibility
    machines&.hours&.since
  end

  # members must have validated at least 1 training and must have a valid yearly subscription to view
  # the trainings further in the futur. This is used to prevent users with a rolling subscription to take
  # their first training in a very long delay.
  # @param user [User,NilClass]
  def show_more_trainings?(user)
    user&.trainings&.size&.positive? && subscription_year?(user)
  end
end
