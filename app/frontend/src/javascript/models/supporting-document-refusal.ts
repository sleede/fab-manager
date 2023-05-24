import { ApiFilter } from './api';

export interface SupportingDocumentRefusalIndexFilter extends ApiFilter {
  supportable_id: number,
  supportable_type: 'User' | 'Child',
}

export interface SupportingDocumentRefusal {
  id: number,
  message: string,
  supportable_id: number,
  supportable_type: 'User' | 'Child',
  operator_id: number,
  supporting_document_type_ids: Array<number>,
}
