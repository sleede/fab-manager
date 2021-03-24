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
    return SettingAPI.toSettingsMap(res?.data);
  }

  static get (name: SettingName): IWrapPromise<Setting> {
    const api = new SettingAPI();
    return wrapPromise(api.get(name));
  }

  static query(names: Array<SettingName>): IWrapPromise<Map<SettingName, any>> {
    const api = new SettingAPI();
    return wrapPromise(api.query(names));
  }

  private

  static toSettingsMap(data: Object): Map<SettingName, any> {
    const dataArray: Array<Array<string | any>> = Object.entries(data);
    const map = new Map();
    dataArray.forEach(item => {
      map.set(SettingName[item[0]], item[1]);
    });
    return map;
  }
}

