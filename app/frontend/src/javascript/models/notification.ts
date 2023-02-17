import { TDateISO } from '../typings/date-iso';

import { notificationTypeNames } from './notification-type';

export type NotificationName = typeof notificationTypeNames[number];

export interface Notification {
  id: number,
  notification_type_id: number,
  notification_type: NotificationName,
  created_at: TDateISO,
  is_read: boolean,
  message: {
    title: string,
    description: string
  }
}

export interface NotificationsTotals {
  total: number,
  unread: number
}

export interface NotificationsIndex {
  totals: NotificationsTotals,
  notifications: Array<Notification>
}
