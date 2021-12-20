import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';

export default class MachineAPI {
  static async index (filters?: boolean): Promise<Array<any>> {
    const res: AxiosResponse<Array<any>> = await apiClient.get(`/api/spaces${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<any> {
    const res: AxiosResponse<any> = await apiClient.get(`/api/spaces/${id}`);
    return res?.data;
  }

  private static filtersToQuery (filters?: boolean): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
