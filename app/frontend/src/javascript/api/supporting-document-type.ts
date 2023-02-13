import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { SupportingDocumentType, SupportingDocumentTypeIndexfilter } from '../models/supporting-document-type';
import ApiLib from '../lib/api';

export default class SupportingDocumentTypeAPI {
  static async index (filters?: SupportingDocumentTypeIndexfilter): Promise<Array<SupportingDocumentType>> {
    const res: AxiosResponse<Array<SupportingDocumentType>> = await apiClient.get(`/api/supporting_document_types${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<SupportingDocumentType> {
    const res: AxiosResponse<SupportingDocumentType> = await apiClient.get(`/api/supporting_document_types/${id}`);
    return res?.data;
  }

  static async create (proofOfIdentityType: SupportingDocumentType): Promise<SupportingDocumentType> {
    const res: AxiosResponse<SupportingDocumentType> = await apiClient.post('/api/supporting_document_types', { supporting_document_type: proofOfIdentityType });
    return res?.data;
  }

  static async update (proofOfIdentityType: SupportingDocumentType): Promise<SupportingDocumentType> {
    const res: AxiosResponse<SupportingDocumentType> = await apiClient.patch(`/api/supporting_document_types/${proofOfIdentityType.id}`, { supporting_document_type: proofOfIdentityType });
    return res?.data;
  }

  static async destroy (proofOfIdentityTypeId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/supporting_document_types/${proofOfIdentityTypeId}`);
    return res?.data;
  }
}
