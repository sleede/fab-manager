# frozen_string_literal: true

require 'test_helper'

class Trainings::AuthorizationServiceTest < ActiveSupport::TestCase
  setup do
    @training = Training.find(4)
    @user = User.find(9)
  end

  test 'training authorization is revoked after 6 month' do
    # Mark training to auto-revoke after 6 month
    @training.update(
      authorization: true,
      authorization_period: 6
    )
    # User validates a training
    StatisticProfileTraining.create!(
      statistic_profile_id: @user.statistic_profile.id,
      training_id: @training.id
    )

    # jump to the future and proceed with auto revocations
    travel_to(6.months.from_now + 1.day)
    Trainings::AuthorizationService.auto_cancel_authorizations(@training)

    # Check authorization was revoked
    assert_nil StatisticProfileTraining.find_by(statistic_profile_id: @user.statistic_profile.id, training_id: @training.id)
    assert_not @user.training_machine?(Machine.find(3))

    # Check notification was sent
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_training_authorization_expired'),
      attached_object_type: 'Training',
      attached_object_id: @training.id
    )
    assert_not_nil notification, 'user notification was not created'
  end

  test 'training with default general parameters' do
    assert_not Trainings::AuthorizationService.override_settings?(@training)
  end

  test 'training with specific parameters' do
    @training.update(authorization: true, authorization_period: 3)
    assert Trainings::AuthorizationService.override_settings?(@training)
  end
end
