import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { OrderPayment } from '../models/order';

export default class CheckoutAPI {
  static async payment (token: string, paymentId?: string): Promise<OrderPayment> {
    const res: AxiosResponse<OrderPayment> = await apiClient.post('/api/checkout/payment', {
      order_token: token,
      payment_id: paymentId
    });
    return res?.data;
  }

  static async confirmPayment (token: string, paymentId: string): Promise<OrderPayment> {
    const res: AxiosResponse<OrderPayment> = await apiClient.post('/api/checkout/confirm_payment', {
      order_token: token,
      payment_id: paymentId
    });
    return res?.data;
  }
}
