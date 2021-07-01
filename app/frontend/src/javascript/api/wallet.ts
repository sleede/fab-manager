import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Wallet } from '../models/wallet';

export default class WalletAPI {
  static async getByUser (userId: number): Promise<Wallet> {
    const res: AxiosResponse = await apiClient.get(`/api/wallet/by_user/${userId}`);
    return res?.data;
  }
}
