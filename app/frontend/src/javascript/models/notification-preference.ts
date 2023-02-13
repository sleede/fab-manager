import { NotificationTypeName, NotificationCategoryName } from './notification-type';

export interface NotificationPreference {
  id: number,
  notification_type: NotificationTypeName,
  email: boolean,
  in_system: boolean
}

export type NotificationPreferencesByCategories = Record<NotificationCategoryName, Array<NotificationPreference>> | Record<never, never>
