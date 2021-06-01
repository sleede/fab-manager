import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ShoppingCart, IntentConfirmation, PaymentConfirmation, UpdateCardResponse } from '../models/payment';
import { PaymentSchedule } from '../models/payment-schedule';
import { Invoice } from '../models/invoice';

export default class StripeAPI {
  static async confirm (stp_payment_method_id: string, cart_items: ShoppingCart): Promise<PaymentConfirmation|Invoice> {
    const res: AxiosResponse<PaymentConfirmation|Invoice> = await apiClient.post(`/api/stripe/confirm_payment`, {
      payment_method_id: stp_payment_method_id,
      cart_items
    });
    return res?.data;
  }

  static async setupIntent (user_id: number): Promise<IntentConfirmation> {
    const res: AxiosResponse<IntentConfirmation> = await apiClient.get(`/api/stripe/setup_intent/${user_id}`);
    return res?.data;
  }

  static async confirmPaymentSchedule (setup_intent_id: string, cart_items: ShoppingCart): Promise<PaymentSchedule> {
    const res: AxiosResponse<PaymentSchedule> = await apiClient.post(`/api/stripe/confirm_payment_schedule`, {
      setup_intent_id,
      cart_items
    });
    return res?.data;
  }

  static async updateCard (user_id: number, stp_payment_method_id: string): Promise<UpdateCardResponse> {
    const res: AxiosResponse<UpdateCardResponse> = await apiClient.post(`/api/stripe/update_card`, {
      user_id,
      payment_method_id: stp_payment_method_id,
    });
    return res?.data;
  }
}

