import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Machine, MachineIndexFilter } from '../models/machine';
import ApiLib from '../lib/api';

export default class MachineAPI {
  static async index (filters?: MachineIndexFilter): Promise<Array<Machine>> {
    const res: AxiosResponse<Array<Machine>> = await apiClient.get(`/api/machines${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<Machine> {
    const res: AxiosResponse<Machine> = await apiClient.get(`/api/machines/${id}`);
    return res?.data;
  }
}
