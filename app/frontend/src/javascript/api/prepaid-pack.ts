import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { PackIndexFilter, PrepaidPack } from '../models/prepaid-pack';

export default class PrepaidPackAPI {
  static async index (filters?: PackIndexFilter): Promise<Array<PrepaidPack>> {
    const res: AxiosResponse<Array<PrepaidPack>> = await apiClient.get(`/api/prepaid_packs${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<PrepaidPack> {
    const res: AxiosResponse<PrepaidPack> = await apiClient.get(`/api/prepaid_packs/${id}`);
    return res?.data;
  }

  static async create (pack: PrepaidPack): Promise<PrepaidPack> {
    const res: AxiosResponse<PrepaidPack> = await apiClient.post('/api/prepaid_packs', { pack });
    return res?.data;
  }

  static async update (pack: PrepaidPack): Promise<PrepaidPack> {
    const res: AxiosResponse<PrepaidPack> = await apiClient.patch(`/api/prepaid_packs/${pack.id}`, { pack });
    return res?.data;
  }

  static async destroy (packId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/prepaid_packs/${packId}`);
    return res?.data;
  }

  private static filtersToQuery(filters?: PackIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }

}

