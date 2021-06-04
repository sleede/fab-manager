import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { ComputePriceResult } from '../models/price';

export default class PriceAPI {
  static async compute (cart: ShoppingCart): Promise<ComputePriceResult> {
    const res: AxiosResponse = await apiClient.post(`/api/prices/compute`, cart);
    return res?.data;
  }
}

