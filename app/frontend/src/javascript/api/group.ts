import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Group, GroupIndexFilter } from '../models/group';
import ApiLib from '../lib/api';

export default class GroupAPI {
  static async index (filters?: GroupIndexFilter): Promise<Array<Group>> {
    const res: AxiosResponse<Array<Group>> = await apiClient.get(`/api/groups${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }
}
