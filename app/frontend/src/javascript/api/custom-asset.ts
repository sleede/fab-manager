import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { CustomAsset, CustomAssetName } from '../models/custom-asset';

export default class CustomAssetAPI {
  static async get (name: CustomAssetName): Promise<CustomAsset> {
    const res: AxiosResponse = await apiClient.get(`/api/custom_assets/${name}`);
    return res?.data?.custom_asset;
  }
}
