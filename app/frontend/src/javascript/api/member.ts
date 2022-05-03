import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { serialize } from 'object-to-formdata';
import { User, UserIndexFilter } from '../models/user';

export default class MemberAPI {
  static async list (filters: UserIndexFilter): Promise<Array<User>> {
    const res: AxiosResponse<Array<User>> = await apiClient.post('/api/members/list', filters);
    return res?.data;
  }

  static async create (user: User): Promise<User> {
    const data = serialize({ user });
    if (user.profile_attributes.user_avatar_attributes.attachment_files[0]) {
      data.set('user[profile_attributes][user_avatar_attributes][attachment]', user.profile_attributes.user_avatar_attributes.attachment_files[0]);
    }
    const res: AxiosResponse<User> = await apiClient.post('/api/members/create', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (user: User): Promise<User> {
    const data = serialize({ user });
    if (user.profile_attributes.user_avatar_attributes.attachment_files[0]) {
      data.set('user[profile_attributes][user_avatar_attributes][attachment]', user.profile_attributes.user_avatar_attributes.attachment_files[0]);
    }
    const res: AxiosResponse<User> = await apiClient.patch(`/api/members/${user.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }
}
