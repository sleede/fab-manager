import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';

export default class PlanLimitationAPI {
  static async destroy (id: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/plan_limitations/${id}`);
    return res?.data;
  }
}
