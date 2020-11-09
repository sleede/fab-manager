import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import { CustomAsset } from '../models/custom-asset';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';

export default class CustomAssetAPI {
  async get (name: string): Promise<CustomAsset> {
    const res: AxiosResponse = await apiClient.get(`/api/custom_assets/${name}`);
    return res?.data?.custom_asset;
  }

  static get (name: string): IWrapPromise<CustomAsset> {
    const api = new CustomAssetAPI();
    return wrapPromise(api.get(name));
  }
}

