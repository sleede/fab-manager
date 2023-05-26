# frozen_string_literal: true

NOTIFICATIONS_TYPES = [
  { name: 'notify_admin_when_project_published', category: 'projects', is_configurable: true },
  { name: 'notify_project_collaborator_to_valid', category: 'projects', is_configurable: false },
  { name: 'notify_project_author_when_collaborator_valid', category: 'projects', is_configurable: true },
  { name: 'notify_user_training_valid', category: 'trainings', is_configurable: false },
  { name: 'notify_member_subscribed_plan', category: 'subscriptions', is_configurable: false },
  { name: 'notify_member_create_reservation', category: 'agenda', is_configurable: false },
  { name: 'notify_member_subscribed_plan_is_changed', category: 'deprecated', is_configurable: false },
  { name: 'notify_admin_member_create_reservation', category: 'agenda', is_configurable: true },
  { name: 'notify_member_slot_is_modified', category: 'agenda', is_configurable: false },
  { name: 'notify_admin_slot_is_modified', category: 'agenda', is_configurable: true },

  { name: 'notify_admin_when_user_is_created', category: 'users_accounts', is_configurable: true },
  { name: 'notify_admin_subscribed_plan', category: 'subscriptions', is_configurable: true },
  { name: 'notify_user_when_invoice_ready', category: 'payments', is_configurable: true },
  { name: 'notify_member_subscription_will_expire_in_7_days', category: 'subscriptions', is_configurable: false },
  { name: 'notify_member_subscription_is_expired', category: 'subscriptions', is_configurable: false },
  { name: 'notify_admin_subscription_will_expire_in_7_days', category: 'subscriptions', is_configurable: true },
  { name: 'notify_admin_subscription_is_expired', category: 'subscriptions', is_configurable: true },
  { name: 'notify_admin_subscription_canceled', category: 'subscriptions', is_configurable: true },
  { name: 'notify_member_subscription_canceled', category: 'subscriptions', is_configurable: false },
  { name: 'notify_user_when_avoir_ready', category: 'wallet', is_configurable: false },

  { name: 'notify_member_slot_is_canceled', category: 'agenda', is_configurable: false },
  { name: 'notify_admin_slot_is_canceled', category: 'agenda', is_configurable: true },
  { name: 'notify_partner_subscribed_plan', category: 'subscriptions', is_configurable: false },
  { name: 'notify_member_subscription_extended', category: 'subscriptions', is_configurable: false },
  { name: 'notify_admin_subscription_extended', category: 'subscriptions', is_configurable: true },
  { name: 'notify_admin_user_group_changed', category: 'users_accounts', is_configurable: true },
  { name: 'notify_user_user_group_changed', category: 'users_accounts', is_configurable: false },
  { name: 'notify_admin_when_user_is_imported', category: 'users_accounts', is_configurable: true },
  { name: 'notify_user_profile_complete', category: 'users_accounts', is_configurable: false },
  { name: 'notify_user_auth_migration', category: 'user', is_configurable: false },

  { name: 'notify_admin_user_merged', category: 'users_accounts', is_configurable: true },
  { name: 'notify_admin_profile_complete', category: 'users_accounts', is_configurable: true },
  { name: 'notify_admin_abuse_reported', category: 'projects', is_configurable: true },
  { name: 'notify_admin_invoicing_changed', category: 'deprecated', is_configurable: false },
  { name: 'notify_user_wallet_is_credited', category: 'wallet', is_configurable: false },
  { name: 'notify_admin_user_wallet_is_credited', category: 'wallet', is_configurable: true },
  { name: 'notify_admin_export_complete', category: 'exports', is_configurable: false },
  { name: 'notify_member_about_coupon', category: 'agenda', is_configurable: false },
  { name: 'notify_member_reservation_reminder', category: 'agenda', is_configurable: false },

  { name: 'notify_admin_free_disk_space', category: 'app_management', is_configurable: false },
  { name: 'notify_admin_close_period_reminder', category: 'accountings', is_configurable: true },
  { name: 'notify_admin_archive_complete', category: 'accountings', is_configurable: true },
  { name: 'notify_privacy_policy_changed', category: 'app_management', is_configurable: false },
  { name: 'notify_admin_import_complete', category: 'app_management', is_configurable: false },
  { name: 'notify_admin_refund_created', category: 'wallet', is_configurable: true },
  { name: 'notify_admins_role_update', category: 'users_accounts', is_configurable: true },
  { name: 'notify_user_role_update', category: 'users_accounts', is_configurable: false },
  { name: 'notify_admin_objects_stripe_sync', category: 'payments', is_configurable: false },
  { name: 'notify_user_when_payment_schedule_ready', category: 'payments', is_configurable: false },

  { name: 'notify_admin_payment_schedule_failed', category: 'payments', is_configurable: true },
  { name: 'notify_member_payment_schedule_failed', category: 'payments', is_configurable: false },
  { name: 'notify_admin_payment_schedule_check_deadline', category: 'payments', is_configurable: true },
  { name: 'notify_admin_payment_schedule_transfer_deadline', category: 'payments', is_configurable: true },
  { name: 'notify_admin_payment_schedule_error', category: 'payments', is_configurable: true },
  { name: 'notify_member_payment_schedule_error', category: 'payments', is_configurable: false },
  { name: 'notify_admin_payment_schedule_gateway_canceled', category: 'payments', is_configurable: true },
  { name: 'notify_member_payment_schedule_gateway_canceled', category: 'payments', is_configurable: false },
  { name: 'notify_admin_user_supporting_document_files_created', category: 'supporting_documents', is_configurable: true },
  { name: 'notify_admin_user_supporting_document_files_updated', category: 'supporting_documents', is_configurable: true },

  { name: 'notify_user_is_validated', category: 'users_accounts', is_configurable: false },
  { name: 'notify_user_is_invalidated', category: 'users_accounts', is_configurable: false },
  { name: 'notify_user_supporting_document_refusal', category: 'supporting_documents', is_configurable: false },
  { name: 'notify_admin_user_supporting_document_refusal', category: 'supporting_documents', is_configurable: true },
  { name: 'notify_user_order_is_ready', category: 'shop', is_configurable: false },
  { name: 'notify_user_order_is_canceled', category: 'shop', is_configurable: false },
  { name: 'notify_user_order_is_refunded', category: 'shop', is_configurable: false },
  { name: 'notify_admin_low_stock_threshold', category: 'shop', is_configurable: true },
  { name: 'notify_admin_training_auto_cancelled', category: 'trainings', is_configurable: true },
  { name: 'notify_member_training_auto_cancelled', category: 'trainings', is_configurable: false }
].freeze

NOTIFICATIONS_TYPES.each do |notification_type|
  next if NotificationType.find_by(name: notification_type[:name])

  NotificationType.create!(
    name: notification_type[:name],
    category: notification_type[:category],
    is_configurable: notification_type[:is_configurable]
  )
end

unless NotificationType.find_by(name: 'notify_admin_user_child_supporting_document_refusal')
  NotificationType.create!(
    name: 'notify_admin_user_child_supporting_document_refusal',
    category: 'supporting_documents',
    is_configurable: true
  )
end

unless NotificationType.find_by(name: 'notify_user_child_supporting_document_refusal')
  NotificationType.create!(
    name: 'notify_user_child_supporting_document_refusal',
    category: 'supporting_documents',
    is_configurable: false
  )
end
