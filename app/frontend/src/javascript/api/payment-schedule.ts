import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import {
  CancelScheduleResponse,
  CashCheckResponse, PayItemResponse,
  PaymentSchedule,
  PaymentScheduleIndexRequest, RefreshItemResponse
} from '../models/payment-schedule';

export default class PaymentScheduleAPI {
  static async list (query: PaymentScheduleIndexRequest): Promise<Array<PaymentSchedule>> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/list`, query);
    return res?.data;
  }

  static async index (query: PaymentScheduleIndexRequest): Promise<Array<PaymentSchedule>> {
    const res: AxiosResponse = await apiClient.get(`/api/payment_schedules?page=${query.query.page}&size=${query.query.size}`);
    return res?.data;
  }

  static async cashCheck(paymentScheduleItemId: number): Promise<CashCheckResponse> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/items/${paymentScheduleItemId}/cash_check`);
    return res?.data;
  }

  static async refreshItem(paymentScheduleItemId: number): Promise<RefreshItemResponse> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/items/${paymentScheduleItemId}/refresh_item`);
    return res?.data;
  }

  static async payItem(paymentScheduleItemId: number): Promise<PayItemResponse> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/items/${paymentScheduleItemId}/pay_item`);
    return res?.data;
  }

  static async cancel (paymentScheduleId: number): Promise<CancelScheduleResponse> {
    const res: AxiosResponse = await apiClient.put(`/api/payment_schedules/${paymentScheduleId}/cancel`);
    return res?.data;
  }
}

