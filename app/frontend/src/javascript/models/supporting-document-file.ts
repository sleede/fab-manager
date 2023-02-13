import { ApiFilter } from './api';

export interface SupportingDocumentFileIndexFilter extends ApiFilter {
  user_id: number,
}

export interface SupportingDocumentFile {
  id?: number,
  attachment?: string,
  user_id?: number,
  supporting_document_type_id: number,
}
