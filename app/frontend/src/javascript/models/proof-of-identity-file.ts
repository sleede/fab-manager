import { ApiFilter } from './api';

export interface ProofOfIdentityFileIndexFilter extends ApiFilter {
  user_id: number,
}

export interface ProofOfIdentityFile {
  id?: number,
  attachment?: string,
  user_id?: number,
  proof_of_identity_type_id: number,
}
