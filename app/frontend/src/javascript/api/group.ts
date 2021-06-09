import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Group } from '../models/group';

export default class GroupAPI {
  static async index (): Promise<Array<Group>> {
    const res: AxiosResponse<Array<Group>> = await apiClient.get('/api/groups');
    return res?.data;
  }
}

