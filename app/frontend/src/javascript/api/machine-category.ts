import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { MachineCategory } from '../models/machine-category';

export default class MachineCategoryAPI {
  static async index (): Promise<Array<MachineCategory>> {
    const res: AxiosResponse<Array<MachineCategory>> = await apiClient.get('/api/machine_categories');
    return res?.data;
  }

  static async create (category: MachineCategory): Promise<MachineCategory> {
    const res: AxiosResponse<MachineCategory> = await apiClient.post('/api/machine_categories', { machine_category: category });
    return res?.data;
  }

  static async update (category: MachineCategory): Promise<MachineCategory> {
    const res: AxiosResponse<MachineCategory> = await apiClient.patch(`/api/machine_categories/${category.id}`, { machine_category: category });
    return res?.data;
  }

  static async destroy (categoryId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/machine_categories/${categoryId}`);
    return res?.data;
  }
}
