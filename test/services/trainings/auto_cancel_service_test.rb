# frozen_string_literal: true

require 'test_helper'

class Trainings::AutoCancelServiceTest < ActiveSupport::TestCase
  include ApplicationHelper

  setup do
    @training = Training.find(4)
    @availability = Availability.find(22)
  end

  test 'auto cancel reservation with less reservations than the threshold' do
    Setting.set('wallet_module', false)
    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    customer = User.find(3)
    slot = @availability.slots.first
    r = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: customer).id
    )
    Trainings::AutoCancelService.auto_cancel_reservations(@training)

    # Check availability was locked
    @availability.reload
    assert @availability.lock

    # Check reservation was cancelled
    r.reload
    assert_not_nil r.slots_reservations.first&.canceled_at

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_training_auto_cancelled'),
      attached_object_type: 'SlotsReservation',
      attached_object_id: r.slots_reservations.first&.id
    )
    assert_not_nil notification, 'user notification was not created'
    assert_not notification.get_meta_data(:auto_refund)

    # Check notification was sent to the admin
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_admin_training_auto_cancelled'),
      attached_object_type: 'Availability',
      attached_object_id: @availability.id
    )
    assert_not_nil notification, 'admin notification was not created'
    assert_not notification.get_meta_data(:auto_refund)
  end

  test 'do not auto cancel reservation with more reservations than the threshold' do
    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    slot = @availability.slots.first

    # first reservation
    c1 = User.find(2)
    r1 = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: c1).id
    )

    # second reservation
    c2 = User.find(3)
    r2 = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: c2).id
    )

    # third reservation
    c3 = User.find(3)
    r3 = Reservation.create!(
      reservable_id: @training.id,
      reservable_type: Training.name,
      slots_reservations_attributes: [{ slot_id: slot.id }],
      statistic_profile_id: StatisticProfile.find_by(user: c3).id
    )

    Trainings::AutoCancelService.auto_cancel_reservations(@training)

    # Check availability was not locked
    @availability.reload
    assert_not @availability.lock

    # Check nothing was cancelled
    r1.reload
    assert_nil r1.slots_reservations.first&.canceled_at
    r2.reload
    assert_nil r2.slots_reservations.first&.canceled_at
    r3.reload
    assert_nil r3.slots_reservations.first&.canceled_at

    # Check no notifications were sent
    assert_empty Notification.where(
      notification_type_id: NotificationType.find_by(name: 'notify_member_training_auto_cancelled'),
      attached_object_type: 'SlotsReservation',
      attached_object_id: [r1.slots_reservations.first&.id, r2.slots_reservations.first&.id, r3.slots_reservations.first&.id]
    )
    assert_nil Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_admin_training_auto_cancelled'),
      attached_object_type: 'Availability',
      attached_object_id: @availability.id
    )
  end

  test 'auto cancel reservation but do not generate any refunds if it was free' do
    Setting.set('wallet_module', true)

    wallet_transactions = WalletTransaction.count

    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    # user 3 has subscription's credits from training 4
    customer = User.find(3)
    slot = @availability.slots.first

    # Reserve through the cart service to get an invoice associated with the reservation
    cs = CartService.new(User.admins.first)
    cs.from_hash(ActionController::Parameters.new({
                                                    customer_id: customer.id,
                                                    items: [
                                                      reservation: {
                                                        reservable_id: @training.id,
                                                        reservable_type: @training.class.name,
                                                        slots_reservations_attributes: [{ slot_id: slot.id }]
                                                      }
                                                    ]
                                                  })).build_and_save(nil, nil)

    # Go with cancelling
    Trainings::AutoCancelService.auto_cancel_reservations(@training)

    # Check reservation was cancelled
    r = Reservation.last
    assert_not_nil r.slots_reservations.first&.canceled_at

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_training_auto_cancelled'),
      attached_object_type: 'SlotsReservation',
      attached_object_id: r.slots_reservations.first&.id
    )
    assert_not_nil notification, 'user notification was not created'
    assert notification.get_meta_data(:auto_refund)

    # Check notification was sent to the admin
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_admin_training_auto_cancelled'),
      attached_object_type: 'Availability',
      attached_object_id: @availability.id
    )
    assert_not_nil notification, 'admin notification was not created'
    assert notification.get_meta_data(:auto_refund)

    # Check customer was not refunded on his wallet
    assert_equal wallet_transactions, WalletTransaction.count
  end

  test 'auto cancel reservation and generate a refund' do
    Setting.set('wallet_module', true)

    wallet_transactions = WalletTransaction.count

    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    customer = User.find(4)
    slot = @availability.slots.first

    # Reserve through the cart service to get an invoice associated with the reservation
    cs = CartService.new(User.admins.first)
    cs.from_hash(ActionController::Parameters.new({
                                                    customer_id: customer.id,
                                                    items: [
                                                      reservation: {
                                                        reservable_id: @training.id,
                                                        reservable_type: @training.class.name,
                                                        slots_reservations_attributes: [{ slot_id: slot.id }]
                                                      }
                                                    ]
                                                  })).build_and_save(nil, nil)

    # Go with cancelling
    Trainings::AutoCancelService.auto_cancel_reservations(@training)

    # Check reservation was cancelled
    r = Reservation.last
    assert_not_nil r.slots_reservations.first&.canceled_at

    # Check notification was sent to the user
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_member_training_auto_cancelled'),
      attached_object_type: 'SlotsReservation',
      attached_object_id: r.slots_reservations.first&.id
    )
    assert_not_nil notification, 'user notification was not created'
    assert notification.get_meta_data(:auto_refund)

    # Check notification was sent to the admin
    notification = Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_admin_training_auto_cancelled'),
      attached_object_type: 'Availability',
      attached_object_id: @availability.id
    )
    assert_not_nil notification, 'admin notification was not created'
    assert notification.get_meta_data(:auto_refund)

    # Check customer was refunded on his wallet
    assert_equal wallet_transactions + 1, WalletTransaction.count
    transaction = WalletTransaction.last
    assert_equal transaction.wallet.user.id, customer.id
    assert_equal transaction.transaction_type, 'credit'
    assert_equal to_centimes(transaction.amount), r.invoice_items.first.amount
  end

  test 'training with default general parameters' do
    assert_not Trainings::AutoCancelService.override_settings?(@training)
  end

  test 'training with specific parameters' do
    @training.update(auto_cancel: true, auto_cancel_threshold: 3, auto_cancel_deadline: 24)
    assert Trainings::AutoCancelService.override_settings?(@training)
  end
end
