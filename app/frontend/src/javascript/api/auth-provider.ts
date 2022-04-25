import { AuthenticationProvider, MappingFields } from '../models/authentication-provider';
import { AxiosResponse } from 'axios';
import apiClient from './clients/api-client';

export default class AuthProviderAPI {
  static async index (): Promise<Array<AuthenticationProvider>> {
    const res: AxiosResponse<Array<AuthenticationProvider>> = await apiClient.get('/api/auth_providers');
    return res?.data;
  }

  static async get (id: number): Promise<AuthenticationProvider> {
    const res: AxiosResponse<AuthenticationProvider> = await apiClient.get(`/api/auth_providers/${id}`);
    return res?.data;
  }

  static async create (authProvider: AuthenticationProvider): Promise<AuthenticationProvider> {
    const res: AxiosResponse<AuthenticationProvider> = await apiClient.post('/api/auth_providers', authProvider);
    return res?.data;
  }

  static async update (authProvider: AuthenticationProvider): Promise<AuthenticationProvider> {
    const res: AxiosResponse<AuthenticationProvider> = await apiClient.put(`/api/auth_providers/${authProvider.id}`, authProvider);
    return res?.data;
  }

  static async delete (id: number): Promise<void> {
    await apiClient.delete(`/api/auth_providers/${id}`);
  }

  static async mappingFields (): Promise<MappingFields> {
    const res: AxiosResponse<MappingFields> = await apiClient.get('/api/auth_providers/mapping_fields');
    return res?.data;
  }

  static async strategyName (authProvider: AuthenticationProvider): Promise<string> {
    const res: AxiosResponse<string> = await apiClient.get(`/api/auth_providers/strategy_name?providable_type=${authProvider.providable_type}&name=${authProvider.name}`);
    return res?.data;
  }
}
