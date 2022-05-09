import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Tag } from '../models/tag';

export default class TagAPI {
  static async index (): Promise<Array<Tag>> {
    const res: AxiosResponse<Array<Tag>> = await apiClient.get('/api/tags');
    return res?.data;
  }
}
