import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { User, UserIndexFilter } from '../models/user';

export default class MemberAPI {
  static async list (filters: UserIndexFilter): Promise<Array<User>> {
    const res: AxiosResponse<Array<User>> = await apiClient.post('/api/members/list', filters);
    return res?.data;
  }

  static async create (user: User): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.post('/api/members/create', { user });
    return res?.data;
  }

  static async update (user: User): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.patch(`/api/members/${user.id}`, { user });
    return res?.data;
  }
}
