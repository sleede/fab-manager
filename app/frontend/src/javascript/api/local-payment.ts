import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { PaymentSchedule } from '../models/payment-schedule';
import { Invoice } from '../models/invoice';

export default class LocalPaymentAPI {
  static async confirmPayment (cartItems: ShoppingCart): Promise<PaymentSchedule|Invoice> {
    const res: AxiosResponse<PaymentSchedule|Invoice> = await apiClient.post('/api/local_payment/confirm_payment', cartItems);
    return res?.data;
  }
}
