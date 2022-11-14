import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Plan, PlansDuration } from '../models/plan';
import ApiLib from '../lib/api';

export default class PlanAPI {
  static async index (): Promise<Array<Plan>> {
    const res: AxiosResponse<Array<Plan>> = await apiClient.get('/api/plans');
    return res?.data;
  }

  static async durations (): Promise<Array<PlansDuration>> {
    const res: AxiosResponse<Array<PlansDuration>> = await apiClient.get('/api/plans/durations');
    return res?.data;
  }

  static async create (plan: Plan): Promise<Plan> {
    const data = ApiLib.serializeAttachments(plan, 'plan', ['plan_file_attributes']);
    const res: AxiosResponse<Plan> = await apiClient.post('/api/plans', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (plan: Plan): Promise<Plan> {
    const data = ApiLib.serializeAttachments(plan, 'plan', ['plan_file_attributes']);
    const res: AxiosResponse<Plan> = await apiClient.put(`/api/plans/${plan.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async get (id: number): Promise<Plan> {
    const res: AxiosResponse<Plan> = await apiClient.get(`/api/plans/${id}`);
    return res?.data;
  }
}
