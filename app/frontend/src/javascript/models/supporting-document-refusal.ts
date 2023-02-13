import { ApiFilter } from './api';

export interface SupportingDocumentRefusalIndexFilter extends ApiFilter {
  user_id: number,
}

export interface SupportingDocumentRefusal {
  id: number,
  message: string,
  user_id: number,
  operator_id: number,
  supporting_document_type_ids: Array<number>,
}
