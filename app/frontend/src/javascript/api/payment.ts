import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import { CartItems, PaymentConfirmation } from '../models/payment';

export default class PaymentAPI {
  static async confirm (stp_payment_method_id: string, cart_items: CartItems): Promise<PaymentConfirmation> {
    const res: AxiosResponse = await apiClient.post(`/api/payments/confirm_payment`, {
      payment_method_id: stp_payment_method_id,
      cart_items
    });
    return res?.data;
  }
}

