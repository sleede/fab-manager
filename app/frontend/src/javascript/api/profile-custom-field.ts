import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProfileCustomField } from '../models/profile-custom-field';

export default class ProfileCustomFieldAPI {
  static async index (): Promise<Array<ProfileCustomField>> {
    const res: AxiosResponse<Array<ProfileCustomField>> = await apiClient.get('/api/profile_custom_fields');
    return res?.data;
  }

  static async get (id: number): Promise<ProfileCustomField> {
    const res: AxiosResponse<ProfileCustomField> = await apiClient.get(`/api/profile_custom_fields/${id}`);
    return res?.data;
  }

  static async create (profileCustomField: ProfileCustomField): Promise<ProfileCustomField> {
    const res: AxiosResponse<ProfileCustomField> = await apiClient.post('/api/profile_custom_fields', { profile_custom_field: profileCustomField });
    return res?.data;
  }

  static async update (profileCustomField: ProfileCustomField): Promise<ProfileCustomField> {
    const res: AxiosResponse<ProfileCustomField> = await apiClient.patch(`/api/profile_custom_fields/${profileCustomField.id}`, { profile_custom_field: profileCustomField });
    return res?.data;
  }

  static async destroy (profileCustomFieldId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/profile_custom_fields/${profileCustomFieldId}`);
    return res?.data;
  }
}
