import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Order, OrderIndexFilter, OrderIndex } from '../models/order';
import ApiLib from '../lib/api';

export default class OrderAPI {
  static async index (filters?: OrderIndexFilter): Promise<OrderIndex> {
    const res: AxiosResponse<OrderIndex> = await apiClient.get(`/api/orders${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number | string): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.get(`/api/orders/${id}`);
    return res?.data;
  }

  static async updateState (order: Order, state: string, note?: string): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.patch(`/api/orders/${order.id}`, { order: { state, note } });
    return res?.data;
  }
}
