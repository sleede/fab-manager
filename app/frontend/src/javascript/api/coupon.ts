import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Coupon } from '../models/coupon';

export default class CouponAPI {
  static async validate (code: string, amount: number, userId?: number): Promise<Coupon> {
    const res: AxiosResponse<Coupon> = await apiClient.post('/api/coupons/validate', { code, amount, user_id: userId });
    return res?.data;
  }
}
