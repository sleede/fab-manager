# frozen_string_literal: true

# Creates Notification Types table to record every notification type (previously
# stored in an Array), and records the existing types.

# This migration is linked to the abandon of the NotifyWith gem. Notification Types
# will now be store in database and we will manage ourself the Notification system.
class CreateNotificationTypes < ActiveRecord::Migration[5.2]
  # Index start at 1. This is required due to previous functionning of the NotifyWith gem
  NOTIFICATIONS_TYPES = [
    { id: 1, name: 'notify_admin_when_project_published', category: 'projects', is_configurable: true },
    { id: 2, name: 'notify_project_collaborator_to_valid', category: 'projects', is_configurable: true },
    { id: 3, name: 'notify_project_author_when_collaborator_valid', category: 'projects', is_configurable: true },
    { id: 4, name: 'notify_user_training_valid', category: 'trainings', is_configurable: false },
    { id: 5, name: 'notify_member_subscribed_plan', category: 'subscriptions', is_configurable: false },
    { id: 6, name: 'notify_member_create_reservation', category: 'agenda', is_configurable: false },
    { id: 7, name: 'notify_member_subscribed_plan_is_changed', category: 'deprecated', is_configurable: false },
    { id: 8, name: 'notify_admin_member_create_reservation', category: 'agenda', is_configurable: true },
    { id: 9, name: 'notify_member_slot_is_modified', category: 'agenda', is_configurable: false },
    { id: 10, name: 'notify_admin_slot_is_modified', category: 'agenda', is_configurable: true },

    { id: 11, name: 'notify_admin_when_user_is_created', category: 'users_accounts', is_configurable: true },
    { id: 12, name: 'notify_admin_subscribed_plan', category: 'subscriptions', is_configurable: true },
    { id: 13, name: 'notify_user_when_invoice_ready', category: 'payments', is_configurable: true },
    { id: 14, name: 'notify_member_subscription_will_expire_in_7_days', category: 'subscriptions', is_configurable: false },
    { id: 15, name: 'notify_member_subscription_is_expired', category: 'subscriptions', is_configurable: false },
    { id: 16, name: 'notify_admin_subscription_will_expire_in_7_days', category: 'subscriptions', is_configurable: true },
    { id: 17, name: 'notify_admin_subscription_is_expired', category: 'subscriptions', is_configurable: true },
    { id: 18, name: 'notify_admin_subscription_canceled', category: 'subscriptions', is_configurable: true },
    { id: 19, name: 'notify_member_subscription_canceled', category: 'subscriptions', is_configurable: false },
    { id: 20, name: 'notify_user_when_avoir_ready', category: 'wallet', is_configurable: false },

    { id: 21, name: 'notify_member_slot_is_canceled', category: 'agenda', is_configurable: false },
    { id: 22, name: 'notify_admin_slot_is_canceled', category: 'agenda', is_configurable: true },
    { id: 23, name: 'notify_partner_subscribed_plan', category: 'subscriptions', is_configurable: false },
    { id: 24, name: 'notify_member_subscription_extended', category: 'subscriptions', is_configurable: false },
    { id: 25, name: 'notify_admin_subscription_extended', category: 'subscriptions', is_configurable: true },
    { id: 26, name: 'notify_admin_user_group_changed', category: 'users_accounts', is_configurable: true },
    { id: 27, name: 'notify_user_user_group_changed', category: 'users_accounts', is_configurable: false },
    { id: 28, name: 'notify_admin_when_user_is_imported', category: 'users_accounts', is_configurable: true },
    { id: 29, name: 'notify_user_profile_complete', category: 'users_accounts', is_configurable: false },
    { id: 30, name: 'notify_user_auth_migration', category: 'user', is_configurable: false },

    { id: 31, name: 'notify_admin_user_merged', category: 'users_accounts', is_configurable: true },
    { id: 32, name: 'notify_admin_profile_complete', category: 'users_accounts', is_configurable: true },
    { id: 33, name: 'notify_admin_abuse_reported', category: 'projects', is_configurable: true },
    { id: 34, name: 'notify_admin_invoicing_changed', category: 'deprecated', is_configurable: false },
    { id: 35, name: 'notify_user_wallet_is_credited', category: 'wallet', is_configurable: false },
    { id: 36, name: 'notify_admin_user_wallet_is_credited', category: 'wallet', is_configurable: true },
    { id: 37, name: 'notify_admin_export_complete', category: 'exports', is_configurable: false },
    { id: 38, name: 'notify_member_about_coupon', category: 'agenda', is_configurable: false },
    { id: 39, name: 'notify_member_reservation_reminder', category: 'agenda', is_configurable: false },

    { id: 40, name: 'notify_admin_free_disk_space', category: 'app_management', is_configurable: false },
    { id: 41, name: 'notify_admin_close_period_reminder', category: 'accountings', is_configurable: true },
    { id: 42, name: 'notify_admin_archive_complete', category: 'accountings', is_configurable: true },
    { id: 43, name: 'notify_privacy_policy_changed', category: 'app_management', is_configurable: false },
    { id: 44, name: 'notify_admin_import_complete', category: 'app_management', is_configurable: false },
    { id: 45, name: 'notify_admin_refund_created', category: 'wallet', is_configurable: true },
    { id: 46, name: 'notify_admins_role_update', category: 'users_accounts', is_configurable: true },
    { id: 47, name: 'notify_user_role_update', category: 'users_accounts', is_configurable: false },
    { id: 48, name: 'notify_admin_objects_stripe_sync', category: 'payments', is_configurable: false },
    { id: 49, name: 'notify_user_when_payment_schedule_ready', category: 'payments', is_configurable: false },

    { id: 50, name: 'notify_admin_payment_schedule_failed', category: 'payments', is_configurable: true },
    { id: 51, name: 'notify_member_payment_schedule_failed', category: 'payments', is_configurable: false },
    { id: 52, name: 'notify_admin_payment_schedule_check_deadline', category: 'payments', is_configurable: true },
    { id: 53, name: 'notify_admin_payment_schedule_transfer_deadline', category: 'payments', is_configurable: true },
    { id: 54, name: 'notify_admin_payment_schedule_error', category: 'payments', is_configurable: true },
    { id: 55, name: 'notify_member_payment_schedule_error', category: 'payments', is_configurable: false },
    { id: 56, name: 'notify_admin_payment_schedule_gateway_canceled', category: 'payments', is_configurable: true },
    { id: 57, name: 'notify_member_payment_schedule_gateway_canceled', category: 'payments', is_configurable: false },
    { id: 58, name: 'notify_admin_user_supporting_document_files_created', category: 'supporting_documents', is_configurable: true },
    { id: 59, name: 'notify_admin_user_supporting_document_files_updated', category: 'supporting_documents', is_configurable: true },

    { id: 60, name: 'notify_user_is_validated', category: 'users_accounts', is_configurable: false },
    { id: 61, name: 'notify_user_is_invalidated', category: 'users_accounts', is_configurable: false },
    { id: 62, name: 'notify_user_supporting_document_refusal', category: 'supporting_documents', is_configurable: false },
    { id: 63, name: 'notify_admin_user_supporting_document_refusal', category: 'supporting_documents', is_configurable: true },
    { id: 64, name: 'notify_user_order_is_ready', category: 'shop', is_configurable: true },
    { id: 65, name: 'notify_user_order_is_canceled', category: 'shop', is_configurable: true },
    { id: 66, name: 'notify_user_order_is_refunded', category: 'shop', is_configurable: true },
    { id: 67, name: 'notify_admin_low_stock_threshold', category: 'shop', is_configurable: true },
    { id: 68, name: 'notify_admin_training_auto_cancelled', category: 'trainings', is_configurable: true },
    { id: 69, name: 'notify_member_training_auto_cancelled', category: 'trainings', is_configurable: false }
  ].freeze

  def up
    create_table :notification_types do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.boolean :is_configurable, null: false

      t.timestamps
    end

    add_index :notification_types, :name, unique: true

    # Records previous notification types
    NOTIFICATIONS_TYPES.each do |notification_type|
      NotificationType.create!(
        id: notification_type[:id],
        name: notification_type[:name],
        category: notification_type[:category],
        is_configurable: notification_type[:is_configurable]
      )
    end

    last_id = NotificationType.order(:id).last.id
    execute "SELECT setval('public.notification_types_id_seq', #{last_id})"

    add_foreign_key :notifications, :notification_types
  end

  def down
    remove_foreign_key :notifications, :notification_types
    drop_table :notification_types
  end
end
