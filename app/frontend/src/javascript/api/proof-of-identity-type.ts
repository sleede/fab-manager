import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProofOfIdentityType, ProofOfIdentityTypeIndexfilter } from '../models/proof-of-identity-type';
import ApiLib from '../lib/api';

export default class ProofOfIdentityTypeAPI {
  static async index (filters?: ProofOfIdentityTypeIndexfilter): Promise<Array<ProofOfIdentityType>> {
    const res: AxiosResponse<Array<ProofOfIdentityType>> = await apiClient.get(`/api/proof_of_identity_types${ApiLib.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<ProofOfIdentityType> {
    const res: AxiosResponse<ProofOfIdentityType> = await apiClient.get(`/api/proof_of_identity_types/${id}`);
    return res?.data;
  }

  static async create (proofOfIdentityType: ProofOfIdentityType): Promise<ProofOfIdentityType> {
    const res: AxiosResponse<ProofOfIdentityType> = await apiClient.post('/api/proof_of_identity_types', { proof_of_identity_type: proofOfIdentityType });
    return res?.data;
  }

  static async update (proofOfIdentityType: ProofOfIdentityType): Promise<ProofOfIdentityType> {
    const res: AxiosResponse<ProofOfIdentityType> = await apiClient.patch(`/api/proof_of_identity_types/${proofOfIdentityType.id}`, { proof_of_identity_type: proofOfIdentityType });
    return res?.data;
  }

  static async destroy (proofOfIdentityTypeId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/proof_of_identity_types/${proofOfIdentityTypeId}`);
    return res?.data;
  }
}
