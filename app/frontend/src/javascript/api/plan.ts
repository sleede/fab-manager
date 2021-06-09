import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Plan } from '../models/plan';

export default class PlanAPI {
  static async index (): Promise<Array<Plan>> {
    const res: AxiosResponse<Array<Plan>> = await apiClient.get('/api/plans');
    return res?.data;
  }
}

