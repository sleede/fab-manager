import { ApiFilter } from './api';

export interface ProofOfIdentityTypeIndexfilter extends ApiFilter {
  group_id?: number,
}

export interface ProofOfIdentityType {
  id: number,
  name: string,
  group_ids: Array<number>
}
