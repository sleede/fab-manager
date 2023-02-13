import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { NotificationTypeIndexFilter, NotificationType } from '../models/notification-type';
import ApiLib from '../lib/api';

export default class NotificationTypesAPI {
  static async index (filters?:NotificationTypeIndexFilter): Promise<Array<NotificationType>> {
    const res: AxiosResponse<Array<NotificationType>> = await apiClient.get(`/api/notification_types${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }
}
