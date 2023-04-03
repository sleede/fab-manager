import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Child, ChildIndexFilter } from '../models/child';
import ApiLib from '../lib/api';

export default class ChildAPI {
  static async index (filters: ChildIndexFilter): Promise<Array<Child>> {
    const res: AxiosResponse<Array<Child>> = await apiClient.get(`/api/children${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<Child> {
    const res: AxiosResponse<Child> = await apiClient.get(`/api/children/${id}`);
    return res?.data;
  }

  static async create (child: Child): Promise<Child> {
    const res: AxiosResponse<Child> = await apiClient.post('/api/children', { child });
    return res?.data;
  }

  static async update (child: Child): Promise<Child> {
    const res: AxiosResponse<Child> = await apiClient.patch(`/api/children/${child.id}`, { child });
    return res?.data;
  }

  static async destroy (childId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/children/${childId}`);
    return res?.data;
  }
}
