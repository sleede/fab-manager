import apiClient from './clients/api-client';
import { Subscription, SubscriptionPaymentDetails, UpdateSubscriptionRequest } from '../models/subscription';
import { AxiosResponse } from 'axios';

export default class SubscriptionAPI {
  static async update (request: UpdateSubscriptionRequest): Promise<Subscription> {
    const res: AxiosResponse<Subscription> = await apiClient.patch(`/api/subscriptions/${request.id}`, { subscription: request });
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
