import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Machine } from '../models/machine';

export default class MachineAPI {
  static async index (): Promise<Array<Machine>> {
    const res: AxiosResponse<Array<Machine>> = await apiClient.get(`/api/machines`);
    return res?.data;
  }

  static async get (id: number): Promise<Machine> {
    const res: AxiosResponse<Machine> = await apiClient.get(`/api/machines/${id}`);
    return res?.data;
  }
}

