# frozen_string_literal: true

unless NotificationType.find_by(name: 'notify_member_training_authorization_expired')
  NotificationType.create!(
    name: 'notify_member_training_authorization_expired',
    category: 'trainings',
    is_configurable: false
  )
end

unless NotificationType.find_by(name: 'notify_member_training_invalidated')
  NotificationType.create!(
    name: 'notify_member_training_invalidated',
    category: 'trainings',
    is_configurable: false
  )
end

unless NotificationType.find_by(name: 'notify_admin_order_is_paid')
  NotificationType.create!(
    name: 'notify_admin_order_is_paid',
    category: 'shop',
    is_configurable: true
  )
end

unless NotificationType.find_by(name: 'notify_member_reservation_limit_reached')
  NotificationType.create!(
    name: 'notify_member_reservation_limit_reached',
    category: 'agenda',
    is_configurable: false
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

unless NotificationType.find_by(name: 'notify_admin_child_created')
  NotificationType.create!(
    name: 'notify_admin_child_created',
    category: 'users_accounts',
    is_configurable: true
  )
end

unless NotificationType.find_by(name: 'notify_user_child_is_validated')
  NotificationType.create!(
    name: 'notify_user_child_is_validated',
    category: 'users_accounts',
    is_configurable: false
  )
end

unless NotificationType.find_by(name: 'notify_user_child_is_invalidated')
  NotificationType.create!(
    name: 'notify_user_child_is_invalidated',
    category: 'users_accounts',
    is_configurable: false
  )
end

unless NotificationType.find_by(name: 'notify_admin_user_child_supporting_document_files_updated')
  NotificationType.create!(
    name: 'notify_admin_user_child_supporting_document_files_updated',
    category: 'supporting_documents',
    is_configurable: true
  )
end

unless NotificationType.find_by(name: 'notify_admin_user_child_supporting_document_files_created')
  NotificationType.create!(
    name: 'notify_admin_user_child_supporting_document_files_created',
    category: 'supporting_documents',
    is_configurable: true
  )
end
