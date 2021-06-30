import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { PaymentSchedule } from '../models/payment-schedule';
import { Invoice } from '../models/invoice';

export default class LocalPaymentAPI {
  static async confirmPayment (cart_items: ShoppingCart): Promise<PaymentSchedule|Invoice> {
    const res: AxiosResponse<PaymentSchedule|Invoice> = await apiClient.post('/api/local_payment/confirm_payment', cart_items);
    return res?.data;
  }
}

