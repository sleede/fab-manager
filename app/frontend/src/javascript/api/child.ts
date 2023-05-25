import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Child, ChildIndexFilter } from '../models/child';
import ApiLib from '../lib/api';

export default class ChildAPI {
  static async index (filters: ChildIndexFilter): Promise<Array<Child>> {
    const res: AxiosResponse<Array<Child>> = await apiClient.get(`/api/children${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<Child> {
    const res: AxiosResponse<Child> = await apiClient.get(`/api/children/${id}`);
    return res?.data;
  }

  static async create (child: Child): Promise<Child> {
    const data = ApiLib.serializeAttachments(child, 'child', ['supporting_document_files_attributes']);
    const res: AxiosResponse<Child> = await apiClient.post('/api/children', data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async update (child: Child): Promise<Child> {
    const data = ApiLib.serializeAttachments(child, 'child', ['supporting_document_files_attributes']);
    const res: AxiosResponse<Child> = await apiClient.put(`/api/children/${child.id}`, data, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res?.data;
  }

  static async destroy (childId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/children/${childId}`);
    return res?.data;
  }

  static async validate (child: Child): Promise<Child> {
    const res: AxiosResponse<Child> = await apiClient.patch(`/api/children/${child.id}/validate`, { child });
    return res?.data;
  }
}
