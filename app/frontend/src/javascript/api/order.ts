import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Order, OrderIndexFilter, OrderIndex } from '../models/order';
import ApiLib from '../lib/api';

export default class ProductAPI {
  static async index (filters?: OrderIndexFilter): Promise<OrderIndex> {
    const res: AxiosResponse<OrderIndex> = await apiClient.get(`/api/orders${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number | string): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.get(`/api/orders/${id}`);
    return res?.data;
  }
}
