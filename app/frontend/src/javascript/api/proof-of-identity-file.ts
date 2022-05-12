import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { ProofOfIdentityFile, ProofOfIdentityFileIndexFilter } from '../models/proof-of-identity-file';

export default class ProofOfIdentityFileAPI {
  static async index (filters?: ProofOfIdentityFileIndexFilter): Promise<Array<ProofOfIdentityFile>> {
    const res: AxiosResponse<Array<ProofOfIdentityFile>> = await apiClient.get(`/api/proof_of_identity_files${this.filtersToQuery(filters)}`);
    return res?.data;
  }

  static async get (id: number): Promise<ProofOfIdentityFile> {
    const res: AxiosResponse<ProofOfIdentityFile> = await apiClient.get(`/api/proof_of_identity_files/${id}`);
    return res?.data;
  }

  static async create (proofOfIdentityFile: FormData): Promise<ProofOfIdentityFile> {
    const res: AxiosResponse<ProofOfIdentityFile> = await apiClient.post('/api/proof_of_identity_files', proofOfIdentityFile);
    return res?.data;
  }

  static async update (id: number, proofOfIdentityFile: FormData): Promise<ProofOfIdentityFile> {
    const res: AxiosResponse<ProofOfIdentityFile> = await apiClient.patch(`/api/proof_of_identity_files/${id}`, proofOfIdentityFile);
    return res?.data;
  }

  static async destroy (proofOfIdentityFileId: number): Promise<void> {
    const res: AxiosResponse<void> = await apiClient.delete(`/api/proof_of_identity_files/${proofOfIdentityFileId}`);
    return res?.data;
  }

  private static filtersToQuery (filters?: ProofOfIdentityFileIndexFilter): string {
    if (!filters) return '';

    return '?' + Object.entries(filters).map(f => `${f[0]}=${f[1]}`).join('&');
  }
}
