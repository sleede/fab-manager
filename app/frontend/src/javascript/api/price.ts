import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';
import { CartItems } from '../models/payment';
import { ComputePriceResult } from '../models/price';

export default class PriceAPI {
  async compute (cartItems: CartItems): Promise<ComputePriceResult> {
    const res: AxiosResponse = await apiClient.post(`/api/prices/compute`, cartItems);
    return res?.data?.custom_asset;
  }

  static compute (cartItems: CartItems): IWrapPromise<ComputePriceResult> {
    const api = new PriceAPI();
    return wrapPromise(api.compute(cartItems));
  }
}

