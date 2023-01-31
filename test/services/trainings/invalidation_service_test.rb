# frozen_string_literal: true

require 'test_helper'

class Trainings::InvalidationServiceTest < ActiveSupport::TestCase
  setup do
    @training = Training.find(4)
    @user = User.find(9)
  end

  test 'training authorization is invalidated after 6 month without reservations' do
    # Mark training to invalidable after 6 month
    @training.update(
      invalidation: true,
      invalidation_period: 6
    )
    # User validates a training
    StatisticProfileTraining.create!(
      statistic_profile_id: @user.statistic_profile.id,
      training_id: @training.id
    )

    # jump to the future and proceed with auto invalidations
    travel_to(DateTime.current + 6.months + 1.day)
    Trainings::InvalidationService.auto_invalidate(@training)

    # Check authorization was revoked
    assert_nil StatisticProfileTraining.find_by(statistic_profile_id: @user.statistic_profile.id, training_id: @training.id)
    assert_not @user.training_machine?(Machine.find(3))

    # Check notification was sent
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by_name('notify_member_training_invalidated'), # rubocop:disable Rails/DynamicFindBy
      attached_object_type: 'Training',
      attached_object_id: @training.id
    )
    assert_not_nil notification, 'user notification was not created'
  end

  test 'training authorization is not invalidated after 6 month with some reservations' do
    # Mark training to invalidable after 6 month
    @training.update(
      invalidation: true,
      invalidation_period: 6
    )
    # User validates a training
    StatisticProfileTraining.create!(
      statistic_profile_id: @user.statistic_profile.id,
      training_id: @training.id
    )

    # User reserves a machine authorized by this training
    machine = @training.machines.first
    slot = machine.availabilities.where('start_at > ?', DateTime.current).first&.slots&.first
    Reservation.create!(
      reservable_id: machine.id,
      reservable_type: Machine.name,
      slots_reservations_attributes: [{ slot_id: slot&.id }],
      statistic_profile_id: @user.statistic_profile.id
    )

    # jump to the future and proceed with auto invalidations
    travel_to(DateTime.current + 6.months + 1.day)
    Trainings::InvalidationService.auto_invalidate(@training)

    # Check authorization was not revoked
    assert_not_nil StatisticProfileTraining.find_by(statistic_profile_id: @user.statistic_profile.id, training_id: @training.id)
    assert @user.training_machine?(machine)

    # Check notification was not sent
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by_name('notify_member_training_invalidated'), # rubocop:disable Rails/DynamicFindBy
      attached_object_type: 'Training',
      attached_object_id: @training.id
    )
    assert_nil notification
  end

  test 'training with default general parameters' do
    assert_not Trainings::InvalidationService.override_settings?(@training)
  end

  test 'training with specific parameters' do
    @training.update(invalidation: true, invalidation_period: 3)
    assert Trainings::InvalidationService.override_settings?(@training)
  end
end
