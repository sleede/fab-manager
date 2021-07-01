import apiClient from './clients/api-client';
import { UserPack, UserPackIndexFilter } from '../models/user-pack';
import { AxiosResponse } from 'axios';

export default class UserPackAPI {
  static async index(filters: UserPackIndexFilter): Promise<Array<UserPack>> {
    const res: AxiosResponse<Array<UserPack>> = await apiClient.get(`/api/user_packs${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  private static filtersToQuery(filters?: UserPackIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
