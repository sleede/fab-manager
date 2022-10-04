import { SettingName, SettingValue } from '../models/setting';

export default class SettingLib {
  /**
   * Convert the provided data to a map, as expected by BulkUpdate
   */
  static bulkObjectToMap = (data: Record<SettingName, SettingValue>): Map<SettingName, SettingValue> => {
    const res = new Map<SettingName, SettingValue>();
    for (const key in data) {
      res.set(key as SettingName, data[key]);
    }
    return res;
  };

  /**
   * Convert the provided map to a simple javascript object
   */
  static mapToBulkObject = (data: Map<SettingName, SettingValue>): Record<SettingName, SettingValue> => {
    const res = {} as Record<SettingName, SettingValue>;
    data.forEach((value, key) => {
      res[key] = value;
    });
    return res;
  };
}
