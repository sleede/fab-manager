import { ApiFilter } from './api';

export interface SupportingDocumentTypeIndexfilter extends ApiFilter {
  group_id?: number,
  document_type?: 'User' | 'Child'
}

export interface SupportingDocumentType {
  id: number,
  name: string,
  group_ids: Array<number>,
  document_type: 'User' | 'Child'
}
