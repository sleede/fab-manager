import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart, IntentConfirmation, PaymentConfirmation, UpdateCardResponse, StripeSubscription } from '../models/payment';
import { PaymentSchedule } from '../models/payment-schedule';
import { Invoice } from '../models/invoice';

export default class StripeAPI {
  static async confirmMethod (paymentMethodId: string, cart_items: ShoppingCart): Promise<PaymentConfirmation|Invoice> {
    const res: AxiosResponse<PaymentConfirmation|Invoice> = await apiClient.post(`/api/stripe/confirm_payment`, {
      payment_method_id: paymentMethodId,
      cart_items
    });
    return res?.data;
  }

  static async confirmIntent (paymentMethodId: string, cartItems: ShoppingCart): Promise<PaymentConfirmation|Invoice> {
    const res: AxiosResponse = await apiClient.post('/api/stripe/confirm_payment', {
      payment_intent_id: paymentMethodId,
      cart_items: cartItems
    });
    return res?.data;
  }

  static async paymentSchedule (paymentMethodId: string, cartItems: ShoppingCart): Promise<StripeSubscription> {
    const res: AxiosResponse = await apiClient.post('/api/stripe/payment_schedule', {
      payment_method_id: paymentMethodId,
      cart_items: cartItems
    });
    return res?.data;
  }

  static async setupIntent (userId: number): Promise<IntentConfirmation> {
    const res: AxiosResponse<IntentConfirmation> = await apiClient.get(`/api/stripe/setup_intent/${userId}`);
    return res?.data;
  }

  static async confirmPaymentSchedule (subscriptionId: string, cartItems: ShoppingCart): Promise<PaymentSchedule> {
    const res: AxiosResponse<PaymentSchedule> = await apiClient.post('/api/stripe/confirm_payment_schedule', {
      subscription_id: subscriptionId,
      cart_items: cartItems
    });
    return res?.data;
  }

  static async updateCard (user_id: number, stp_payment_method_id: string, payment_schedule_id?: number): Promise<UpdateCardResponse> {
    const res: AxiosResponse<UpdateCardResponse> = await apiClient.post(`/api/stripe/update_card`, {
      user_id,
      payment_method_id: stp_payment_method_id,
      payment_schedule_id
    });
    return res?.data;
  }
}

