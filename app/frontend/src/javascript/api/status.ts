import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Status } from '../models/status';

export default class StatusAPI {
  static async index (): Promise<Array<Status>> {
    const res: AxiosResponse<Array<Status>> = await apiClient.get('/api/statuses');
    return res?.data;
  }

  static async create (newStatus: Status): Promise<Status> {
    const res: AxiosResponse<Status> = await apiClient.post('/api/statuses', { status: newStatus });
    return res?.data;
  }

  static async update (updatedStatus: Status): Promise<Status> {
    const res: AxiosResponse<Status> = await apiClient.patch(`/api/statuses/${updatedStatus.id}`, { status: updatedStatus });
    return res?.data;
  }

  static async destroy (statusId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/statuses/${statusId}`);
    return res?.data;
  }
}
