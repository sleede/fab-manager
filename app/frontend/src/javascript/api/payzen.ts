import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart } from '../models/payment';
import { User } from '../models/user';
import {
  CheckHashResponse,
  CreatePaymentResponse,
  CreateTokenResponse,
  SdkTestResponse
} from '../models/payzen';
import { Invoice } from '../models/invoice';
import { PaymentSchedule } from '../models/payment-schedule';

export default class PayzenAPI {
  static async chargeSDKTest (baseURL: string, username: string, password: string): Promise<SdkTestResponse> {
    const res: AxiosResponse<SdkTestResponse> = await apiClient.post('/api/payzen/sdk_test', { base_url: baseURL, username, password });
    return res?.data;
  }

  static async chargeCreatePayment (cart: ShoppingCart, customer: User): Promise<CreatePaymentResponse> {
    const res: AxiosResponse<CreatePaymentResponse> = await apiClient.post('/api/payzen/create_payment', { cart_items: cart, customer_id: customer.id });
    return res?.data;
  }

  static async chargeCreateToken (cart: ShoppingCart, customer: User): Promise<CreateTokenResponse> {
    const res: AxiosResponse = await apiClient.post('/api/payzen/create_token', { cart_items: cart, customer_id: customer.id });
    return res?.data;
  }

  static async checkHash (algorithm: string, hashKey: string, hash: string, data: string): Promise<CheckHashResponse> {
    const res: AxiosResponse<CheckHashResponse> = await apiClient.post('/api/payzen/check_hash', { algorithm, hash_key: hashKey, hash, data });
    return res?.data;
  }

  static async confirm (orderId: string, cart: ShoppingCart): Promise<Invoice> {
    const res: AxiosResponse<Invoice> = await apiClient.post('/api/payzen/confirm_payment', { cart_items: cart, order_id: orderId });
    return res?.data;
  }

  static async confirmPaymentSchedule (orderId: string, transactionUuid: string, cart: ShoppingCart): Promise<PaymentSchedule> {
    const res: AxiosResponse<PaymentSchedule> = await apiClient.post('/api/payzen/confirm_payment_schedule', { cart_items: cart, order_id: orderId, transaction_uuid: transactionUuid });
    return res?.data;
  }

  static async updateToken (paymentScheduleId: number): Promise<CreateTokenResponse> {
    const res: AxiosResponse<CreateTokenResponse> = await apiClient.post('/api/payzen/update_token', { payment_schedule_id: paymentScheduleId });
    return res?.data;
  }

  static async checkCart (cart: ShoppingCart, customer: User): Promise<CreatePaymentResponse> {
    const res: AxiosResponse<CreatePaymentResponse> = await apiClient.post('/api/payzen/check_cart', { cart_items: cart, customer_id: customer.id });
    return res?.data;
  }
}
