import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { SupportingDocumentRefusal, SupportingDocumentRefusalIndexFilter } from '../models/supporting-document-refusal';
import ApiLib from '../lib/api';

export default class SupportingDocumentRefusalAPI {
  static async index (filters?: SupportingDocumentRefusalIndexFilter): Promise<Array<SupportingDocumentRefusal>> {
    const res: AxiosResponse<Array<SupportingDocumentRefusal>> = await apiClient.get(`/api/supporting_document_refusals${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async create (supportingDocumentRefusal: SupportingDocumentRefusal): Promise<SupportingDocumentRefusal> {
    const res: AxiosResponse<SupportingDocumentRefusal> = await apiClient.post('/api/supporting_document_refusals', { supporting_document_refusal: supportingDocumentRefusal });
    return res?.data;
  }
}
