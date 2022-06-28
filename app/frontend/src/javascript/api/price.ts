import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { ComputePriceResult, Price, PriceIndexFilter } from '../models/price';
import ApiLib from '../lib/api';

export default class PriceAPI {
  static async compute (cart: ShoppingCart): Promise<ComputePriceResult> {
    const res: AxiosResponse<ComputePriceResult> = await apiClient.post('/api/prices/compute', cart);
    return res?.data;
  }

  static async index (filters?: PriceIndexFilter): Promise<Array<Price>> {
    const res: AxiosResponse = await apiClient.get(`/api/prices${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async create (price: Price): Promise<Price> {
    const res: AxiosResponse<Price> = await apiClient.post('/api/prices', { price });
    return res?.data;
  }

  static async update (price: Price): Promise<Price> {
    const res: AxiosResponse<Price> = await apiClient.patch(`/api/prices/${price.id}`, { price });
    return res?.data;
  }

  static async destroy (priceId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/prices/${priceId}`);
    return res?.data;
  }
}
