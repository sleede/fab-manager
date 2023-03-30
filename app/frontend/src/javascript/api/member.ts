import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { serialize } from 'object-to-formdata-tz';
import { User, MemberIndexFilter, UserRole } from '../models/user';

export default class MemberAPI {
  static async list (filters: MemberIndexFilter): Promise<Array<User>> {
    const res: AxiosResponse<Array<User>> = await apiClient.post('/api/members/list', filters);
    return res?.data;
  }

  static async search (name: string): Promise<Array<User>> {
    const res: AxiosResponse<Array<User>> = await apiClient.get(`/api/members/search/${name}`);
    return res?.data;
  }

  static async get (id: number): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.get(`/api/members/${id}`);
    return res?.data;
  }

  static async create (user: User): Promise<User> {
    const data = serialize({ user });
    if (user.profile_attributes?.user_avatar_attributes?.attachment_files[0]) {
      data.set('user[profile_attributes][user_avatar_attributes][attachment]', user.profile_attributes.user_avatar_attributes.attachment_files[0]);
    }
    const res: AxiosResponse<User> = await apiClient.post('/api/members', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (user: User): Promise<User> {
    const data = serialize({ user }, { allowEmptyArrays: true });
    if (user.profile_attributes?.user_avatar_attributes?.attachment_files[0]) {
      data.set('user[profile_attributes][user_avatar_attributes][attachment]', user.profile_attributes.user_avatar_attributes.attachment_files[0]);
    }
    const res: AxiosResponse<User> = await apiClient.patch(`/api/members/${user.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async updateRole (user: User, role: UserRole, groupId?: number): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.patch(`/api/members/${user.id}/update_role`, { role, group_id: groupId });
    return res?.data;
  }

  static async current (): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.get('/api/members/current');
    return res?.data;
  }

  static async validate (member: User): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.patch(`/api/members/${member.id}/validate`, { user: member });
    return res?.data;
  }
}
