import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { ComputePriceResult, Price, PriceIndexFilter } from '../models/price';

export default class PriceAPI {
  static async compute (cart: ShoppingCart): Promise<ComputePriceResult> {
    const res: AxiosResponse<ComputePriceResult> = await apiClient.post(`/api/prices/compute`, cart);
    return res?.data;
  }

  static async index (filters?: Array<PriceIndexFilter>): Promise<Array<Price>> {
    const res: AxiosResponse = await apiClient.get(`/api/prices${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async update (price: Price): Promise<Price> {
    const res: AxiosResponse<Price> = await apiClient.patch(`/api/prices/${price.id}`, { price });
    return  res?.data;
  }

  private static filtersToQuery(filters?: Array<PriceIndexFilter>): string {
    if (!filters) return '';

    return '?' + filters.map(f => `${f.key}=${f.value}`).join('&');
  }
}

