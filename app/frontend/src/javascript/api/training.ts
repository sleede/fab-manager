import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Training, TrainingIndexFilter } from '../models/training';
import ApiLib from '../lib/api';

export default class TrainingAPI {
  static async index (filters?: TrainingIndexFilter): Promise<Array<Training>> {
    const res: AxiosResponse<Array<Training>> = await apiClient.get(`/api/trainings${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }
}
