import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { SupportingDocumentFile, SupportingDocumentFileIndexFilter } from '../models/supporting-document-file';
import ApiLib from '../lib/api';

export default class SupportingDocumentFileAPI {
  static async index (filters?: SupportingDocumentFileIndexFilter): Promise<Array<SupportingDocumentFile>> {
    const res: AxiosResponse<Array<SupportingDocumentFile>> = await apiClient.get(`/api/supporting_document_files${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<SupportingDocumentFile> {
    const res: AxiosResponse<SupportingDocumentFile> = await apiClient.get(`/api/supporting_document_files/${id}`);
    return res?.data;
  }

  static async create (proofOfIdentityFile: FormData): Promise<SupportingDocumentFile> {
    const res: AxiosResponse<SupportingDocumentFile> = await apiClient.post('/api/supporting_document_files', proofOfIdentityFile);
    return res?.data;
  }

  static async update (id: number, proofOfIdentityFile: FormData): Promise<SupportingDocumentFile> {
    const res: AxiosResponse<SupportingDocumentFile> = await apiClient.patch(`/api/supporting_document_files/${id}`, proofOfIdentityFile);
    return res?.data;
  }

  static async destroy (proofOfIdentityFileId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/supporting_document_files/${proofOfIdentityFileId}`);
    return res?.data;
  }
}
