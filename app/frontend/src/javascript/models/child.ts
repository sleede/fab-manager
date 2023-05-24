import { TDateISODate } from '../typings/date-iso';
import { ApiFilter } from './api';

export interface ChildIndexFilter extends ApiFilter {
  user_id: number,
}

export interface Child {
  id?: number,
  last_name: string,
  first_name: string,
  email?: string,
  phone?: string,
  birthday: TDateISODate,
  user_id: number,
  supporting_document_files_attributes?: Array<{
    id?: number,
    supportable_id?: number,
    supportable_type?: 'User' | 'Child',
    supporting_document_type_id: number,
    attachment?: File,
    attachment_name?: string,
    attachment_url?: string,
    _destroy?: boolean
  }>,
}
