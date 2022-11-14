import apiClient from './clients/api-client';
import ApiLib from '../lib/api';
import { UserIndexFilter, User } from '../models/user';
import { AxiosResponse } from 'axios';
import { Partner } from '../models/plan';

export default class UserAPI {
  static async index (filters: UserIndexFilter): Promise<Array<User>> {
    const res: AxiosResponse<Array<User>> = await apiClient.get(`/api/users${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async create (user: Partner|User): Promise<User> {
    const data = {
      user: user as Partner,
      manager: user as User
    };
    const res: AxiosResponse<User> = await apiClient.post('/api/users', data);
    return res?.data;
  }
}
