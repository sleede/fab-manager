# frozen_string_literal: true

# Payments module
module Payment; end

# Abstract class that must be implemented by each payment gateway.
# Provides methods to create remote objects on the payment gateway
class Payment::Service
  def create_subscription(_payment_schedule, *args); end

  def cancel_subscription(_payment_schedule); end

  def create_user(_user_id); end

  def create_coupon(_coupon_id); end

  def delete_coupon(_coupon_id); end

  def create_or_update_product(_klass, _id); end

  def process_payment_schedule_item(_payment_schedule_item); end

  def pay_payment_schedule_item(_payment_schedule_item); end

  protected

  # payment has failed but a recovery is still possible
  def notify_payment_schedule_item_failed(payment_schedule_item)
    # notify only for new deadlines, to prevent spamming
    return unless payment_schedule_item.state == 'new'

    NotificationCenter.call type: 'notify_admin_payment_schedule_failed',
                            receiver: User.admins_and_managers,
                            attached_object: payment_schedule_item
    NotificationCenter.call type: 'notify_member_payment_schedule_failed',
                            receiver: payment_schedule_item.payment_schedule.user,
                            attached_object: payment_schedule_item
  end

  # payment has failed and recovery is not possible
  def notify_payment_schedule_item_error(payment_schedule_item)
    # notify only for new deadlines, to prevent spamming
    return unless payment_schedule_item.state == 'new'

    NotificationCenter.call type: 'notify_admin_payment_schedule_error',
                            receiver: User.admins_and_managers,
                            attached_object: payment_schedule_item
    NotificationCenter.call type: 'notify_member_payment_schedule_error',
                            receiver: payment_schedule_item.payment_schedule.user,
                            attached_object: payment_schedule_item
  end

  # payment schedule was cancelled by the gateway
  def notify_payment_schedule_gateway_canceled(payment_schedule_item)
    # notify only for new deadlines, to prevent spamming
    return unless payment_schedule_item.state == 'new'

    NotificationCenter.call type: 'notify_admin_payment_schedule_gateway_canceled',
                            receiver: User.admins_and_managers,
                            attached_object: payment_schedule_item
    NotificationCenter.call type: 'notify_member_payment_schedule_gateway_canceled',
                            receiver: payment_schedule_item.payment_schedule.user,
                            attached_object: payment_schedule_item
  end

end
