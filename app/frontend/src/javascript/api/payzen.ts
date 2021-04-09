import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import { CartItems } from '../models/payment';
import { User } from '../models/user';
import { CreatePaymentResponse, SdkTestResponse } from '../models/payzen';

export default class PayzenAPI {

  static async chargeSDKTest(baseURL: string, username: string, password: string): Promise<SdkTestResponse> {
    const res: AxiosResponse = await apiClient.post('/api/payzen/sdk_test', { base_url: baseURL, username, password });
    return res?.data;
  }

  static async chargeCreatePayment(cart_items: CartItems, customer: User): Promise<CreatePaymentResponse> {
    const res: AxiosResponse = await apiClient.post('/api/payzen/create_payment', { cart_items, customer: { id: customer.id, email: customer.email } });
    return res?.data;
  }
}
