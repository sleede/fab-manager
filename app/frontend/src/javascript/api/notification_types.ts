import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { NotificationTypeIndexFilter, NotificationType } from '../models/notification-type';
import ApiLib from '../lib/api';

export default class NotificationTypesAPI {
  static async index (isConfigurable?:NotificationTypeIndexFilter): Promise<Array<NotificationType>> {
    const res: AxiosResponse<Array<NotificationType>> = await apiClient.get(`/api/notification_types${ApiLib.filtersToQuery(isConfigurable)}`);
    return res?.data;
  }
}
