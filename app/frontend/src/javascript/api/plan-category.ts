import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { PlanCategory } from '../models/plan-category';

export default class PlanCategoryAPI {
  static async index (): Promise<Array<PlanCategory>> {
    const res: AxiosResponse<Array<PlanCategory>> = await apiClient.get('/api/plan_categories');
    return res?.data;
  }

  static async create (category: PlanCategory): Promise<PlanCategory> {
    const res: AxiosResponse<PlanCategory> = await apiClient.post('/api/plan_categories', { plan_category: category });
    return res?.data;
  }

  static async update (category: PlanCategory): Promise<PlanCategory> {
    const res: AxiosResponse<PlanCategory> = await apiClient.patch(`/api/plan_categories/${category.id}`, { plan_category: category });
    return res?.data;
  }

  static async destroy (categoryId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/plan_categories/${categoryId}`);
    return res?.data;
  }
}

