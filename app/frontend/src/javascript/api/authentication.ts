import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { User } from '../models/user';

export default class Authentication {
  static async login (email: string, password: string): Promise<User> {
    const res: AxiosResponse<User> = await apiClient.post('/users/sign_in.json', { email, password });
    return res?.data;
  }

  static async logout (): Promise<void> {
    return apiClient.delete('/users/sign_out.json');
  }

  static async verifyPassword (password: string): Promise<boolean> {
    try {
      const res: AxiosResponse<never> = await apiClient.post('/password/verify.json', { password });
      return (res.status === 200);
    } catch (e) {
      return false;
    }
  }
}
