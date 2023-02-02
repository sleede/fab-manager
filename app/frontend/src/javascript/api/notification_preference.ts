import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { NotificationPreference } from '../models/notification-preference';

export default class NotificationPreferencesAPI {
  static async index (): Promise<Array<NotificationPreference>> {
    const res: AxiosResponse<Array<NotificationPreference>> = await apiClient.get('/api/notification_preferences');
    return res?.data;
  }

  static async update (updatedPreference: NotificationPreference): Promise<NotificationPreference> {
    const res: AxiosResponse<NotificationPreference> = await apiClient.patch(`/api/notification_preferences/${updatedPreference.notification_type}`, { notification_preference: updatedPreference });
    return res?.data;
  }

  static async bulk_update (updatedPreferences: Array<NotificationPreference>): Promise<NotificationPreference> {
    const res: AxiosResponse<NotificationPreference> = await apiClient.patch('/api/notification_preferences/bulk_update', { notification_preferences: updatedPreferences });
    return res?.data;
  }
}
