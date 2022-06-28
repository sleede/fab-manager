import apiClient from './clients/api-client';
import { UserPack, UserPackIndexFilter } from '../models/user-pack';
import { AxiosResponse } from 'axios';
import ApiLib from '../lib/api';

export default class UserPackAPI {
  static async index (filters: UserPackIndexFilter): Promise<Array<UserPack>> {
    const res: AxiosResponse<Array<UserPack>> = await apiClient.get(`/api/user_packs${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }
}
