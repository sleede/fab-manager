import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProofOfIdentityRefusal, ProofOfIdentityRefusalIndexFilter } from '../models/proof-of-identity-refusal';
import ApiLib from '../lib/api';

export default class ProofOfIdentityRefusalAPI {
  static async index (filters?: ProofOfIdentityRefusalIndexFilter): Promise<Array<ProofOfIdentityRefusal>> {
    const res: AxiosResponse<Array<ProofOfIdentityRefusal>> = await apiClient.get(`/api/proof_of_identity_refusals${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async create (proofOfIdentityRefusal: ProofOfIdentityRefusal): Promise<ProofOfIdentityRefusal> {
    const res: AxiosResponse<ProofOfIdentityRefusal> = await apiClient.post('/api/proof_of_identity_refusals', { proof_of_identity_refusal: proofOfIdentityRefusal });
    return res?.data;
  }
}
