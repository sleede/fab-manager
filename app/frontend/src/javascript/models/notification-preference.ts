export interface NotificationPreference {
  id: number,
  notification_type: string,
  email: boolean,
  in_system: boolean
}

// This controls the order of the categories' display in the notification center
export const NotificationCategoryNames = [
  'users_accounts',
  'proof_of_identity',
  'agenda',
  'subscriptions',
  'payments',
  'wallet',
  'shop',
  'projects',
  'accountings',
  'trainings',
  'app_management'
] as const;

export type NotificationCategoryName = typeof NotificationCategoryNames[number];

export type NotificationPreferencesByCategories = Record<NotificationCategoryName, Array<NotificationPreference>> | Record<never, never>
