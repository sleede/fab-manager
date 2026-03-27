import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { AsaasPayment } from '../models/asaas';
import { Order } from '../models/order';
import { Invoice } from '../models/invoice';

export default class AsaasAPI {
  static async createCartPayment (cart: ShoppingCart, cpf: string): Promise<AsaasPayment> {
    const res: AxiosResponse<AsaasPayment> = await apiClient.post('/api/asaas/create_payment', { cart_items: cart, cpf });
    return res?.data;
  }

  static async createOrderPayment (order: Order, cpf: string): Promise<AsaasPayment> {
    const res: AxiosResponse<AsaasPayment> = await apiClient.post('/api/asaas/create_payment', {
      order_token: order.token,
      coupon_code: order.coupon?.code,
      cpf
    });
    return res?.data;
  }

  static async paymentStatus (token: string): Promise<AsaasPayment|Invoice|Order> {
    const res: AxiosResponse<AsaasPayment|Invoice|Order> = await apiClient.get(`/api/asaas/payments/${token}/status`);
    return res?.data;
  }
}
