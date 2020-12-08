import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import { CartItems, IntentConfirmation, PaymentConfirmation } from '../models/payment';

export default class PaymentAPI {
  static async confirm (stp_payment_method_id: string, cart_items: CartItems): Promise<PaymentConfirmation> {
    const res: AxiosResponse = await apiClient.post(`/api/payments/confirm_payment`, {
      payment_method_id: stp_payment_method_id,
      cart_items
    });
    return res?.data;
  }

  static async setupIntent (user_id: number): Promise<IntentConfirmation> {
    const res: AxiosResponse = await apiClient.get(`/api/payments/setup_intent/${user_id}`);
    return res?.data;
  }
}

