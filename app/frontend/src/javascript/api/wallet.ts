import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';
import { Wallet } from '../models/wallet';

export default class WalletAPI {
  async getByUser (user_id: number): Promise<Wallet> {
    const res: AxiosResponse = await apiClient.get(`/api/wallet/by_user/${user_id}`);
    return res?.data;
  }

  static getByUser (user_id: number): IWrapPromise<Wallet> {
    const api = new WalletAPI();
    return wrapPromise(api.getByUser(user_id));
  }
}

