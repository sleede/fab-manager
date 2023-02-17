import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Machine, MachineIndexFilter } from '../models/machine';
import ApiLib from '../lib/api';

export default class MachineAPI {
  static async index (filters?: MachineIndexFilter): Promise<Array<Machine>> {
    const res: AxiosResponse<Array<Machine>> = await apiClient.get(`/api/machines${ApiLib.filtersToQuery(filters, false)}`);
    return res?.data;
  }

  static async get (id: number): Promise<Machine> {
    const res: AxiosResponse<Machine> = await apiClient.get(`/api/machines/${id}`);
    return res?.data;
  }

  static async create (machine: Machine): Promise<Machine> {
    const data = ApiLib.serializeAttachments(machine, 'machine', ['machine_files_attributes', 'machine_image_attributes']);
    const res: AxiosResponse<Machine> = await apiClient.post('/api/machines', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (machine: Machine): Promise<Machine> {
    const data = ApiLib.serializeAttachments(machine, 'machine', ['machine_files_attributes', 'machine_image_attributes']);
    const res: AxiosResponse<Machine> = await apiClient.put(`/api/machines/${machine.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }
}
