import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Order, OrderErrors } from '../models/order';

export default class CartAPI {
  static async create (token?: string): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.post('/api/cart', { order_token: token });
    return res?.data;
  }

  static async addItem (order: Order, orderableId: number, quantity: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/add_item', { order_token: order.token, orderable_id: orderableId, quantity });
    return res?.data;
  }

  static async removeItem (order: Order, orderableId: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/remove_item', { order_token: order.token, orderable_id: orderableId });
    return res?.data;
  }

  static async setQuantity (order: Order, orderableId: number, quantity: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/set_quantity', { order_token: order.token, orderable_id: orderableId, quantity });
    return res?.data;
  }

  static async setOffer (order: Order, orderableId: number, isOffered: boolean): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/set_offer', { order_token: order.token, orderable_id: orderableId, is_offered: isOffered });
    return res?.data;
  }

  static async refreshItem (order: Order, orderableId: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/refresh_item', { order_token: order.token, orderable_id: orderableId });
    return res?.data;
  }

  static async validate (order: Order): Promise<OrderErrors> {
    const res: AxiosResponse<OrderErrors> = await apiClient.post('/api/cart/validate', { order_token: order.token });
    return res?.data;
  }
}
