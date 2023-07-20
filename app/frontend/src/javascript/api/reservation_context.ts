import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ReservationContext } from '../models/reservation';

export default class ReservationContextAPI {
  static async index (): Promise<Array<ReservationContext>> {
    const res: AxiosResponse<Array<ReservationContext>> = await apiClient.get('/api/reservation_contexts');
    return res?.data;
  }
}
