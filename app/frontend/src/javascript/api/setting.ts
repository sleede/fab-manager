import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import {
  Setting,
  SettingBulkArray,
  SettingBulkResult,
  SettingError, SettingGetOptions,
  SettingName,
  SettingValue
} from '../models/setting';
import ApiLib from '../lib/api';

export default class SettingAPI {
  static async get (name: SettingName, options?: SettingGetOptions): Promise<Setting> {
    const res: AxiosResponse<{setting: Setting}> = await apiClient.get(`/api/settings/${name}${ApiLib.filtersToQuery(options)}`);
    return res?.data?.setting;
  }

  static async query (names: readonly SettingName[]): Promise<Map<SettingName, string>> {
    const params = new URLSearchParams();
    params.append('names', `['${names.join("','")}']`);

    const res: AxiosResponse = await apiClient.get(`/api/settings?${params.toString()}`);
    return SettingAPI.toSettingsMap(names, res?.data);
  }

  static async update (name: SettingName, value: SettingValue): Promise<Setting> {
    const res: AxiosResponse = await apiClient.patch(`/api/settings/${name}`, { setting: { value } });
    if (res.status === 304) { return { name, value: `${value}` }; }
    return res?.data?.setting;
  }

  static async bulkUpdate (settings: Map<SettingName, SettingValue>, transactional = false): Promise<Map<SettingName, SettingBulkResult>> {
    const res: AxiosResponse = await apiClient.patch(`/api/settings/bulk_update?transactional=${transactional}`, { settings: SettingAPI.toObjectArray(settings) });
    return SettingAPI.toBulkMap(res?.data?.settings);
  }

  static async isPresent (name: SettingName): Promise<boolean> {
    const res: AxiosResponse = await apiClient.get(`/api/settings/is_present/${name}`);
    return res?.data?.isPresent;
  }

  private static toSettingsMap (names: readonly SettingName[], data: Record<string, string|null>): Map<SettingName, string> {
    const map = new Map();
    names.forEach(name => {
      map.set(name, data[name] || '');
    });
    return map;
  }

  private static toBulkMap (data: Array<Setting|SettingError>): Map<SettingName, SettingBulkResult> {
    const map = new Map();
    data.forEach(item => {
      const itemData: SettingBulkResult = { status: true };
      if ('error' in item) {
        itemData.error = item.error;
        itemData.status = false;
      }
      if ('value' in item) {
        itemData.value = item.value;
      }
      if ('localized' in item) {
        itemData.localized = item.localized;
      }

      map.set(item.name, itemData);
    });
    return map;
  }

  private static toObjectArray (data: Map<SettingName, SettingValue>): SettingBulkArray {
    const array = [];
    data.forEach((value, key) => {
      array.push({
        name: key,
        value
      });
    });
    return array;
  }
}
