import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import { Setting, SettingName } from '../models/setting';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';

export default class SettingAPI {
  async get (name: SettingName): Promise<Setting> {
    const res: AxiosResponse = await apiClient.get(`/api/settings/${name}`);
    return res?.data?.setting;
  }

  async query (names: Array<SettingName>): Promise<Map<SettingName, any>> {
    const res: AxiosResponse = await apiClient.get(`/api/settings/?names=[${names.join(',')}]`);
    return res?.data;
  }

  static get (name: SettingName): IWrapPromise<Setting> {
    const api = new SettingAPI();
    return wrapPromise(api.get(name));
  }

  static query(names: Array<SettingName>): IWrapPromise<Map<SettingName, any>> {
    const api = new SettingAPI();
    return wrapPromise(api.query(names));
  }
}

