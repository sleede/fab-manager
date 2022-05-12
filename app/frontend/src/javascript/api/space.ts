import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Space } from '../models/space';

export default class SpaceAPI {
  static async index (): Promise<Array<Space>> {
    const res: AxiosResponse<Array<Space>> = await apiClient.get('/api/spaces');
    return res?.data;
  }

  static async get (id: number): Promise<Space> {
    const res: AxiosResponse<Space> = await apiClient.get(`/api/spaces/${id}`);
    return res?.data;
  }
}
