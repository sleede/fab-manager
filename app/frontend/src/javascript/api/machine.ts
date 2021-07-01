import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Machine, MachineIndexFilter } from '../models/machine';

export default class MachineAPI {
  static async index (filters?: MachineIndexFilter): Promise<Array<Machine>> {
    const res: AxiosResponse<Array<Machine>> = await apiClient.get(`/api/machines${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<Machine> {
    const res: AxiosResponse<Machine> = await apiClient.get(`/api/machines/${id}`);
    return res?.data;
  }

  private static filtersToQuery (filters?: MachineIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
