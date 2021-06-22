import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Group, GroupIndexFilter } from '../models/group';

export default class GroupAPI {
  static async index (filters?: Array<GroupIndexFilter>): Promise<Array<Group>> {
    const res: AxiosResponse<Array<Group>> = await apiClient.get(`/api/groups${GroupAPI.filtersToQuery(filters)}`);
    return res?.data;
  }

  private static filtersToQuery(filters?: Array<GroupIndexFilter>): string {
    if (!filters) return '';

    return '?' + filters.map(f => `${f.key}=${f.value}`).join('&');
  }
}

