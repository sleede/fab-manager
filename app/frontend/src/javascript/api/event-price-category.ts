import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { EventPriceCategory } from '../models/event';

export default class EventPriceCategoryAPI {
  static async index (): Promise<Array<EventPriceCategory>> {
    const res: AxiosResponse<Array<EventPriceCategory>> = await apiClient.get('/api/price_categories');
    return res?.data;
  }
}
