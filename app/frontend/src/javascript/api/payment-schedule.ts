import apiClient from './api-client';
import { AxiosResponse } from 'axios';
import {
  CashCheckResponse,
  PaymentSchedule,
  PaymentScheduleIndexRequest,
} from '../models/payment-schedule';
import wrapPromise, { IWrapPromise } from '../lib/wrap-promise';

export default class PaymentScheduleAPI {
  async list (query: PaymentScheduleIndexRequest): Promise<Array<PaymentSchedule>> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/list`, query);
    return res?.data;
  }

  async cashCheck(paymentScheduleItemId: number): Promise<CashCheckResponse> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/items/${paymentScheduleItemId}/cash_check`);
    return res?.data;
  }

  async refreshItem(paymentScheduleItemId: number): Promise<void> {
    const res: AxiosResponse = await apiClient.post(`/api/payment_schedules/items/${paymentScheduleItemId}/refresh_item`);
    return res?.data;
  }

  static list (query: PaymentScheduleIndexRequest): IWrapPromise<Array<PaymentSchedule>> {
    const api = new PaymentScheduleAPI();
    return wrapPromise(api.list(query));
  }
}

