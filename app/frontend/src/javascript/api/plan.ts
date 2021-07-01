import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Plan, PlansDuration } from '../models/plan';

export default class PlanAPI {
  static async index (): Promise<Array<Plan>> {
    const res: AxiosResponse<Array<Plan>> = await apiClient.get('/api/plans');
    return res?.data;
  }

  static async durations (): Promise<Array<PlansDuration>> {
    const res: AxiosResponse<Array<PlansDuration>> = await apiClient.get('/api/plans/durations');
    return res?.data;
  }
}
