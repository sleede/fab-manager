# frozen_string_literal: true

# NotificationType defines the different types of Notification.
class NotificationType
  include NotifyWith::NotificationType

  # DANGER: dont remove a notification type!!!
  notification_type_names %w[
    notify_admin_when_project_published
    notify_project_collaborator_to_valid
    notify_project_author_when_collaborator_valid
    notify_user_training_valid
    notify_member_subscribed_plan
    notify_member_create_reservation
    notify_member_subscribed_plan_is_changed
    notify_admin_member_create_reservation
    notify_member_slot_is_modified
    notify_admin_slot_is_modified
    notify_admin_when_user_is_created
    notify_admin_subscribed_plan
    notify_user_when_invoice_ready
    notify_member_subscription_will_expire_in_7_days
    notify_member_subscription_is_expired
    notify_admin_subscription_will_expire_in_7_days
    notify_admin_subscription_is_expired
    notify_admin_subscription_canceled
    notify_member_subscription_canceled
    notify_user_when_avoir_ready
    notify_member_slot_is_canceled
    notify_admin_slot_is_canceled
    notify_partner_subscribed_plan
    notify_member_subscription_extended
    notify_admin_subscription_extended
    notify_admin_user_group_changed
    notify_user_user_group_changed
    notify_admin_when_user_is_imported
    notify_user_profile_complete
    notify_user_auth_migration
    notify_admin_user_merged
    notify_admin_profile_complete
    notify_admin_abuse_reported
    notify_admin_invoicing_changed
    notify_user_wallet_is_credited
    notify_admin_user_wallet_is_credited
    notify_admin_export_complete
    notify_member_about_coupon
    notify_member_reservation_reminder
    notify_admin_free_disk_space
    notify_admin_close_period_reminder
    notify_admin_archive_complete
    notify_privacy_policy_changed
    notify_admin_import_complete
    notify_admin_refund_created
    notify_admins_role_update
    notify_user_role_update
    notify_admin_objects_stripe_sync
    notify_user_when_payment_schedule_ready
    notify_admin_payment_schedule_failed
    notify_member_payment_schedule_failed
    notify_admin_payment_schedule_check_deadline
    notify_admin_payment_schedule_transfer_deadline
    notify_admin_payment_schedule_error
    notify_member_payment_schedule_error
    notify_admin_payment_schedule_gateway_canceled
    notify_member_payment_schedule_gateway_canceled
    notify_admin_user_proof_of_identity_files_created
    notify_admin_user_proof_of_identity_files_updated
    notify_user_is_validated
    notify_user_is_invalidated
    notify_user_proof_of_identity_refusal
    notify_admin_user_proof_of_identity_refusal
  ]
  # deprecated:
  # - notify_member_subscribed_plan_is_changed
  # - notify_admin_invoicing_changed
end
