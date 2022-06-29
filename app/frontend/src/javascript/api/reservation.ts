import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Reservation, ReservationIndexFilter } from '../models/reservation';
import ApiLib from '../lib/api';

export default class ReservationAPI {
  static async index (filters: ReservationIndexFilter): Promise<Array<Reservation>> {
    const res: AxiosResponse<Array<Reservation>> = await apiClient.get(`/api/reservations${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }
}
