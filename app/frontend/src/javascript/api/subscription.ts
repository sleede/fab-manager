import apiClient from './clients/api-client';
import { Subscription, SubscriptionPaymentDetails } from '../models/subscription';
import { AxiosResponse } from 'axios';

export default class SubscriptionAPI {
  static async cancel (id: number): Promise<Subscription> {
    const res: AxiosResponse<Subscription> = await apiClient.patch(`/api/subscriptions/${id}/cancel`);
    return res?.data;
  }

  static async get (id: number): Promise<Subscription> {
    const res: AxiosResponse<Subscription> = await apiClient.get(`/api/subscriptions/${id}`);
    return res?.data;
  }

  static async paymentsDetails (id: number): Promise<SubscriptionPaymentDetails> {
    const res: AxiosResponse<SubscriptionPaymentDetails> = await apiClient.get(`/api/subscriptions/${id}/payment_details`);
    return res?.data;
  }
}
