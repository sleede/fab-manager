import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Order, OrderableType, OrderErrors } from '../models/order';
import { CartItem, CartItemResponse } from '../models/cart_item';

export default class CartAPI {
  static async create (token?: string): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.post('/api/cart', { order_token: token });
    return res?.data;
  }

  static async createItem (order: Order, item: CartItem): Promise<CartItemResponse> {
    const res: AxiosResponse<CartItemResponse> = await apiClient.post('/api/cart/create_item', { order_token: order.token, ...item });
    return res?.data;
  }

  static async addItem (order: Order, orderableId: number, orderableType: OrderableType, quantity: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/add_item', { order_token: order.token, orderable_id: orderableId, orderable_type: orderableType, quantity });
    return res?.data;
  }

  static async removeItem (order: Order, orderableId: number, orderableType: OrderableType): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/remove_item', { order_token: order.token, orderable_id: orderableId, orderable_type: orderableType });
    return res?.data;
  }

  static async setQuantity (order: Order, orderableId: number, orderableType: OrderableType, quantity: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/set_quantity', { order_token: order.token, orderable_id: orderableId, orderable_type: orderableType, quantity });
    return res?.data;
  }

  static async setOffer (order: Order, orderableId: number, orderableType: OrderableType, isOffered: boolean): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/set_offer', { order_token: order.token, orderable_id: orderableId, orderable_type: orderableType, is_offered: isOffered, customer_id: order.user?.id });
    return res?.data;
  }

  static async refreshItem (order: Order, orderableId: number, orderableType: OrderableType): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/refresh_item', { order_token: order.token, orderable_id: orderableId, orderable_type: orderableType });
    return res?.data;
  }

  static async validate (order: Order): Promise<OrderErrors> {
    const res: AxiosResponse<OrderErrors> = await apiClient.post('/api/cart/validate', { order_token: order.token });
    return res?.data;
  }

  static async setCustomer (order: Order, customerId: number): Promise<Order> {
    const res: AxiosResponse<Order> = await apiClient.put('/api/cart/set_customer', { order_token: order.token, user_id: customerId });
    return res?.data;
  }
}
