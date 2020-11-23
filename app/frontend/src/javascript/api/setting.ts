import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import { Setting } from '../models/setting';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';

export default class SettingAPI {
  async get (name: string): Promise<Setting> {
    const res: AxiosResponse = await apiClient.get(`/api/settings/${name}`);
    return res?.data?.setting;
  }

  static get (name: string): IWrapPromise<Setting> {
    const api = new SettingAPI();
    return wrapPromise(api.get(name));
  }
}

