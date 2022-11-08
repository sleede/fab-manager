import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { EventCategory } from '../models/event';

export default class EventCategoryAPI {
  static async index (): Promise<Array<EventCategory>> {
    const res: AxiosResponse<Array<EventCategory>> = await apiClient.get('/api/categories');
    return res?.data;
  }
}
