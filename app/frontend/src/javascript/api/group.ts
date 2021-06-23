import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Group, GroupIndexFilter } from '../models/group';

export default class GroupAPI {
  static async index (filters?: GroupIndexFilter): Promise<Array<Group>> {
    const res: AxiosResponse<Array<Group>> = await apiClient.get(`/api/groups${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  private static filtersToQuery(filters?: GroupIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}

