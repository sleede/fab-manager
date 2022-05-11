import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Training, TrainingIndexFilter } from '../models/training';

export default class TrainingAPI {
  static async index (filters?: TrainingIndexFilter): Promise<Array<Training>> {
    const res: AxiosResponse<Array<Training>> = await apiClient.get(`/api/trainings${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  private static filtersToQuery (filters?: TrainingIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
