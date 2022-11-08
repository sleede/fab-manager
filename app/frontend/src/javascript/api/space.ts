import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Space } from '../models/space';
import ApiLib from '../lib/api';

export default class SpaceAPI {
  static async index (): Promise<Array<Space>> {
    const res: AxiosResponse<Array<Space>> = await apiClient.get('/api/spaces');
    return res?.data;
  }

  static async get (id: number): Promise<Space> {
    const res: AxiosResponse<Space> = await apiClient.get(`/api/spaces/${id}`);
    return res?.data;
  }

  static async create (space: Space): Promise<Space> {
    const data = ApiLib.serializeAttachments(space, 'space', ['space_files_attributes', 'space_image_attributes']);
    const res: AxiosResponse<Space> = await apiClient.post('/api/spaces', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (space: Space): Promise<Space> {
    const data = ApiLib.serializeAttachments(space, 'space', ['space_files_attributes', 'space_image_attributes']);
    const res: AxiosResponse<Space> = await apiClient.put(`/api/spaces/${space.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }
}
