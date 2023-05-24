import { ApiFilter } from './api';

export interface SupportingDocumentFileIndexFilter extends ApiFilter {
  supportable_id: number,
  supportable_type?: 'User' | 'Child',
}

export interface SupportingDocumentFile {
  id?: number,
  attachment?: string,
  supportable_id?: number,
  supportable_type?: 'User' | 'Child',
  supporting_document_type_id: number,
}
