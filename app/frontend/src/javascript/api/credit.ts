import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Credit, CreditableType } from '../models/credit';

export default class CreditAPI {
  static async index (): Promise<Array<Credit>> {
    const res: AxiosResponse<Array<Credit>> = await apiClient.get('/api/credits');
    return res?.data;
  }

  static async userResource (userId: number, resource: CreditableType): Promise<Array<Credit>> {
    const res: AxiosResponse<Array<Credit>> = await apiClient.get(`/api/credits/user/${userId}/${resource}`);
    return res?.data;
  }
}
