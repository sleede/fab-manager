class Slot < ActiveRecord::Base
  include NotifyWith::NotificationAttachedObject

  belongs_to :reservation
  belongs_to :availability

  attr_accessor :is_reserved, :machine, :title, :can_modify, :is_reserved_by_current_user

  after_update :set_ex_start_end_dates_attrs, if: :dates_were_modified?
  after_update :notify_member_and_admin_slot_is_modified, if: :dates_were_modified?

  after_update :notify_member_and_admin_slot_is_canceled, if: :canceled?

  private
  def notify_member_and_admin_slot_is_modified
    NotificationCenter.call type: 'notify_member_slot_is_modified',
                            receiver: reservation.user,
                            attached_object: self
    NotificationCenter.call type: 'notify_admin_slot_is_modified',
                            receiver: User.admins,
                            attached_object: self
  end

  def notify_member_and_admin_slot_is_canceled
    NotificationCenter.call type: 'notify_member_slot_is_canceled',
                            receiver: reservation.user,
                            attached_object: self
    NotificationCenter.call type: 'notify_admin_slot_is_canceled',
                            receiver: User.admins,
                            attached_object: self
  end

  def can_be_modified?
    return false if (start_at - Time.now) / 1.day < 1
    return true
  end

  def dates_were_modified?
    start_at_changed? or end_at_changed?
  end

  def canceled?
    canceled_at_changed?
  end

  def set_ex_start_end_dates_attrs
    update_columns(ex_start_at: start_at_was, ex_end_at: end_at_was)
  end
end
