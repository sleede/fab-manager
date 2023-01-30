import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { NotificationsIndex, Notification } from '../models/notification';

export default class NotificationAPI {
  static async index (page?: number): Promise<NotificationsIndex> {
    const withPage = page ? `?page=${page}` : '';
    const res: AxiosResponse<NotificationsIndex> = await apiClient.get(`/api/notifications${withPage}`);
    return res?.data;
  }

  static async update (updatedNotification: Notification): Promise<Notification> {
    const res: AxiosResponse<Notification> = await apiClient.patch(`/api/notifications/${updatedNotification.id}`, { notification: updatedNotification });
    return res?.data;
  }

  static async update_all (): Promise<void> {
    await apiClient.patch('/api/notifications');
  }
}
