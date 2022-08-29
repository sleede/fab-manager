import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { OrderPayment, Order } from '../models/order';

export default class CheckoutAPI {
  static async payment (order: Order, paymentId?: string): Promise<OrderPayment> {
    const res: AxiosResponse<OrderPayment> = await apiClient.post('/api/checkout/payment', {
      order_token: order.token,
      coupon_code: order.coupon?.code,
      payment_id: paymentId,
      customer_id: order.user.id
    });
    return res?.data;
  }

  static async confirmPayment (order: Order, paymentId: string): Promise<OrderPayment> {
    const res: AxiosResponse<OrderPayment> = await apiClient.post('/api/checkout/confirm_payment', {
      order_token: order.token,
      coupon_code: order.coupon?.code,
      payment_id: paymentId,
      customer_id: order.user.id
    });
    return res?.data;
  }
}
