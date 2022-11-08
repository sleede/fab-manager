import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { AgeRange } from '../models/event';

export default class AgeRangeAPI {
  static async index (): Promise<Array<AgeRange>> {
    const res: AxiosResponse<Array<AgeRange>> = await apiClient.get('/api/age_ranges');
    return res?.data;
  }
}
