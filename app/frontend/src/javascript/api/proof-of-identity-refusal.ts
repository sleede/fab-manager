import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProofOfIdentityRefusal, ProofOfIdentityRefusalIndexFilter } from '../models/proof-of-identity-refusal';

export default class ProofOfIdentityRefusalAPI {
  static async index (filters?: ProofOfIdentityRefusalIndexFilter): Promise<Array<ProofOfIdentityRefusal>> {
    const res: AxiosResponse<Array<ProofOfIdentityRefusal>> = await apiClient.get(`/api/proof_of_identity_refusals${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async create (proofOfIdentityRefusal: ProofOfIdentityRefusal): Promise<ProofOfIdentityRefusal> {
    const res: AxiosResponse<ProofOfIdentityRefusal> = await apiClient.post('/api/proof_of_identity_refusals', { proof_of_identity_refusal: proofOfIdentityRefusal });
    return res?.data;
  }

  private static filtersToQuery (filters?: ProofOfIdentityRefusalIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
