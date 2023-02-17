import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Training, TrainingIndexFilter } from '../models/training';
import ApiLib from '../lib/api';

export default class TrainingAPI {
  static async index (filters?: TrainingIndexFilter): Promise<Array<Training>> {
    const res: AxiosResponse<Array<Training>> = await apiClient.get(`/api/trainings${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async create (training: Training): Promise<Training> {
    const data = ApiLib.serializeAttachments(training, 'training', ['training_image_attributes']);
    const res: AxiosResponse<Training> = await apiClient.post('/api/trainings', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (training: Training): Promise<Training> {
    const data = ApiLib.serializeAttachments(training, 'training', ['training_image_attributes']);
    const res: AxiosResponse<Training> = await apiClient.put(`/api/trainings/${training.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async destroy (trainingId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/trainings/${trainingId}`);
    return res?.data;
  }
}
