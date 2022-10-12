import { SettingName, SettingValue } from '../models/setting';
import ParsingLib from './parsing';

export default class SettingLib {
  /**
   * Convert the provided data to a map, as expected by BulkUpdate
   */
  static objectToBulkMap = (data: Record<SettingName, SettingValue>): Map<SettingName, string> => {
    const res = new Map<SettingName, string>();
    for (const key in data) {
      res.set(key as SettingName, `${data[key]}`);
    }
    return res;
  };

  /**
   * Convert the provided map to a simple javascript object, usable by react-hook-form
   */
  static bulkMapToObject = (data: Map<SettingName, string>): Record<SettingName, SettingValue> => {
    const res = {} as Record<SettingName, SettingValue>;
    data.forEach((value, key) => {
      res[key] = ParsingLib.simpleParse(value);
    });
    return res;
  };
}
